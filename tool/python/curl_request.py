#!/usr/bin/env python3
"""Parse the editor's curl subset without executing curl, shells or requests.

This is the pure import stage, not a complete curl implementation or request
validator. It deliberately omits editor row IDs and blank placeholder rows.
"""
from __future__ import annotations

import argparse
import base64
import json
from pathlib import Path
import re
import sys
from typing import Any
from urllib.parse import parse_qsl

_VENDOR = Path(__file__).resolve().parent / "vendor"
if str(_VENDOR) not in sys.path:
    sys.path.insert(0, str(_VENDOR))
from cli_args import Argument, make_parser

MAX_INPUT_BYTES = 65_536
MAX_TOKENS = 4_096
_PREFIX = "httpDraft.curl."
_ASCII = {code: code - 0xFEE0 for code in range(0xFF01, 0xFF5F)}
_ASCII.update({0x3000: 0x20, 0x2212: 0x2D})
_METHODS = {"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}
_OPTIONS = {
    "-X": "method", "--request": "method", "--url": "url",
    "-H": "header", "--header": "header", "-d": "data", "--data": "data",
    "--data-raw": "data", "--data-binary": "data",
    "--data-urlencode": "urlencode", "-u": "user", "--user": "user",
    "-A": "agent", "--user-agent": "agent", "-e": "referer", "--referer": "referer",
}
_IGNORED = {"-s", "-S", "-i", "-v", "-k", "--silent", "--show-error",
            "--include", "--verbose", "--insecure"}
_SECRET_NAMES = {"authorization", "proxy-authorization", "cookie", "set-cookie",
                 "x-api-key", "api-key", "x-auth-token", "key", "sig", "sas"}
_SECRET_PARTS = ("api-key", "api_key", "token", "secret", "password", "signature",
                 "credential", "access_key", "access-key", "sharedaccesssignature")


class CurlParseError(ValueError):
    """Stable diagnostic code; never includes raw command/credential values."""


def _fail(name: str) -> None:
    raise CurlParseError(_PREFIX + "error." + name)


def tokenize(raw: str) -> list[str]:
    """Match the editor lexer, including empty quotes and literal backslashes.

    shlex is not substituted: it consumes unquoted backslashes that this
    repository's existing editor preserves. This does no shell expansion.
    """
    if not isinstance(raw, str):
        _fail("inputType")
    try:
        size = len(raw.encode("utf-8"))
    except UnicodeEncodeError:
        _fail("encoding")
    if size > MAX_INPUT_BYTES:
        _fail("inputTooLarge")
    if "\x00" in raw:
        _fail("nul")
    text = raw.translate(_ASCII).strip()
    if not text:
        _fail("empty")
    text = re.sub(r"\\\r?\n", " ", text)
    tokens: list[str] = []
    buf: list[str] = []
    quote = ""
    started = False
    index = 0

    def flush() -> None:
        nonlocal started
        if started:
            tokens.append("".join(buf))
            if len(tokens) > MAX_TOKENS:
                _fail("tooManyTokens")
            buf.clear()
            started = False

    while index < len(text):
        char = text[index]
        if quote:
            if char == quote:
                quote = ""
            elif quote == '"' and char == "\\" and index + 1 < len(text):
                index += 1
                following = text[index]
                if following not in '$`"\\\n':
                    buf.append("\\")
                buf.append(following)
            else:
                buf.append(char)
        elif char in "'\"":
            quote = char
            started = True
        elif char in "`$|;<>":
            _fail("shellMeta")
        elif char in " \t\r\n":
            flush()
        else:
            started = True
            buf.append(char)
        index += 1
    if quote:
        _fail("unbalancedQuotes")
    flush()
    return tokens


def _field(name: str, value: str, *, sensitive: bool = False) -> dict[str, Any]:
    return {"name": name, "value": value, "sensitive": sensitive}


def _sensitive(name: str) -> bool:
    name = name.translate(_ASCII).strip().lower()
    return (name in _SECRET_NAMES or name.endswith(("_key", "-key"))
            or any(part in name for part in _SECRET_PARTS))


def _pairs(raw: str) -> list[dict[str, Any]]:
    # urllib's default replaces malformed UTF-8 and tolerates invalid escapes;
    # neither should silently change the editor's input.
    if re.search(r"%(?![0-9a-fA-F]{2})", raw):
        _fail("queryEncoding")
    try:
        return [_field(name, value) for name, value in parse_qsl(
            raw, keep_blank_values=True, errors="strict", separator="&")]
    except UnicodeError:
        _fail("queryEncoding")


def parse_curl(raw: str) -> dict[str, Any]:
    """Return import-stage fields and curl diagnostics, without dispatching.

    RequestDraftValidator warnings (URL validity, duplicate headers, JSON body
    validity) are a separate stage and are not represented by this function.
    """
    errors: list[str] = []
    warnings: list[str] = []
    try:
        tokens = tokenize(raw)
        if not tokens or tokens[0].lower() != "curl":
            _fail("notCurl")
        method, explicit_method, url = "GET", False, None
        headers: list[dict[str, Any]] = []
        chunks: list[str] = []
        encoded: list[dict[str, Any]] = []
        use_get = False
        index = 1
        while index < len(tokens):
            token = tokens[index]
            index += 1
            flag, sep, inline = token.partition("=") if token.startswith("--") else (token, "", "")
            kind = _OPTIONS.get(flag)
            if kind:
                if sep:
                    value = inline
                elif index < len(tokens):
                    value = tokens[index]
                    index += 1
                else:
                    errors.append(_PREFIX + "error.missingArg")
                    break
                if kind == "method":
                    candidate = value.strip().upper()
                    if candidate not in _METHODS:
                        errors.append(_PREFIX + "error.badMethod")
                    else:
                        method, explicit_method = candidate, True
                elif kind == "url":
                    url = value
                elif kind == "header":
                    name, colon, content = value.strip().partition(":")
                    name, content = name.strip(), content.strip()
                    if not colon or not name or any(c in name + content for c in "\r\n"):
                        errors.append(_PREFIX + "error.badHeader")
                    else:
                        headers.append(_field(name, content, sensitive=_sensitive(name) or "***" in content))
                elif kind in ("data", "urlencode"):
                    at, eq = value.find("@"), value.find("=")
                    if value.startswith("@") or (kind == "urlencode" and at >= 0 and (eq < 0 or at < eq)):
                        errors.append(_PREFIX + "error.fileBody")
                    elif kind == "data":
                        chunks.append(value)
                    else:
                        name, _, content = value.partition("=")
                        encoded.append(_field(name, content))
                elif kind == "user":
                    auth = base64.b64encode(value.encode("utf-8")).decode("ascii")
                    headers.append(_field("Authorization", "Basic " + auth, sensitive=True))
                    warnings.append(_PREFIX + "warn.basicAuthMapped")
                else:
                    headers.append(_field("User-Agent" if kind == "agent" else "Referer", value))
            elif flag in ("-G", "--get"):
                use_get = True
            elif flag in ("-I", "--head"):
                method, explicit_method = "HEAD", True
            elif flag in ("-L", "--location"):
                warnings.append(_PREFIX + "warn.ignoredRedirect")
            elif flag in _IGNORED:
                warnings.append(_PREFIX + "warn.ignoredFlag")
            elif token.startswith("-") and len(token) > 1:
                errors.append(_PREFIX + "error.unsupportedFlag")
            elif url is not None:
                errors.append(_PREFIX + "error.extraPositional")
            else:
                url = token
        if errors:
            return {"ok": False, "draft": None, "errors": errors, "warnings": warnings}
        if url is None or not url.strip():
            _fail("urlRequired")
        body_mode, raw_body = "none", ""
        query: list[dict[str, Any]] = []
        form: list[dict[str, Any]] = []
        if encoded:
            if use_get:
                query = encoded
            else:
                body_mode, form = "formUrlEncoded", encoded
                if not explicit_method:
                    method = "POST"
        elif chunks:
            joined = "&".join(chunks)
            if use_get:
                query = _pairs(joined)
            else:
                if not explicit_method:
                    method = "POST"
                content_type = next((h["value"].lower() for h in headers
                                     if h["name"].lower() == "content-type"), "")
                if "application/json" in content_type:
                    body_mode, raw_body = "json", joined
                elif "application/x-www-form-urlencoded" in content_type:
                    body_mode, form = "formUrlEncoded", _pairs(joined)
                elif joined.lstrip().startswith(("{", "[")):
                    body_mode, raw_body = "json", joined
                elif "=" in joined:
                    body_mode, form = "formUrlEncoded", _pairs(joined)
                else:
                    body_mode, raw_body = "raw", joined
        def rows(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
            return [item for item in items if item["name"] or item["value"]]
        draft = {"method": method, "url": url.strip(), "headers": rows(headers),
                 "query": rows(query), "bodyMode": body_mode, "rawBody": raw_body,
                 "formFields": rows(form)}
        return {"ok": True, "draft": draft, "errors": [], "warnings": warnings}
    except CurlParseError as error:
        return {"ok": False, "draft": None, "errors": [str(error)], "warnings": warnings}


def _argument_failure() -> dict[str, Any]:
    return {
        "ok": False,
        "draft": None,
        "errors": [_PREFIX + "error.arguments"],
        "warnings": [],
    }


def main(argv: list[str] | None = None) -> int:
    parser = make_parser(
        [Argument(("--input",), {
            "default": "-",
            "help": "UTF-8 curl text file; - reads stdin",
        })],
        description=__doc__,
        exit_on_error=False,
    )
    try:
        args, extras = parser.parse_known_args(argv)
    except argparse.ArgumentError:
        print(json.dumps(_argument_failure(), ensure_ascii=False))
        return 2
    if extras:
        print(json.dumps(_argument_failure(), ensure_ascii=False))
        return 2
    try:
        if args.input == "-":
            data = sys.stdin.buffer.read(MAX_INPUT_BYTES + 1)
        else:
            with Path(args.input).open("rb") as source:
                data = source.read(MAX_INPUT_BYTES + 1)
        if len(data) > MAX_INPUT_BYTES:
            _fail("inputTooLarge")
        result = parse_curl(data.decode("utf-8"))
    except (OSError, UnicodeError, CurlParseError) as error:
        code = str(error) if isinstance(error, CurlParseError) else _PREFIX + "error.inputRead"
        result = {"ok": False, "draft": None, "errors": [code], "warnings": []}
    # Parsed values can contain credentials. They are returned to the caller,
    # never copied into diagnostics, logs or a shared failure corpus here.
    print(json.dumps(result, ensure_ascii=True, separators=(",", ":")))
    return 0 if result["ok"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
