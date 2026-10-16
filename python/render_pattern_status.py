#!/usr/bin/env python3
"""Render all 198 evidence-based catalogue statuses as a reviewable Markdown table.

The audit's status describes *observed evidence*, not a claim of full feature
completion. In particular a standalone producer is not a Flutter integration.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def escape(value):
    return str(value).replace("|", "\\|").replace("\n", " ").replace("\r", " ")


def _counts(mapping):
    return "、".join(f"{key} {value}" for key, value in mapping.items())


def completion(row):
    status = row["status"]
    if status in ("fake_delayed_success", "description_only", "missing_catalogue_artifact"):
        return "未実装（実機能未確認）"
    if status in ("native_flutter_shared_interaction", "native_flutter_example"):
        return "限定実装（操作・環境別の検証が必要）"
    return "限定実装（統合未証明）"


def render(report, head, tree=None):
    records = report["patterns"]
    if len(records) != 198 or {r["id"] for r in records} != set(range(1, 199)):
        raise ValueError("not a complete 198-pattern inventory")
    summary = report["summary"]
    lines = [
        "# データ処理198パターン 実装・責務分離ステータス",
        "",
        f"- 監査対象コミット: `{head}`",
        *([f"- 監査したツリー: `{tree}`（PR のマージ結果）"] if tree and tree != head else []),
        f"- 監査スキーマ: `{report['schema']}`",
        f"- 対象: **{len(records)}件** / 本番Dart **{summary['dart_files']}ファイル** / 監査エラー **{summary['errors']}件**",
        "- **注意**: これは静的な証跡分類。完全実装・E2E成功を自動認定するものではない。",
        "- Python/JSのproducerが存在しても、Flutter画面からの実行接続は別途検証する。",
        "- `限定実装` は完成を意味しない。実行可能範囲と残課題を必ず参照する。",
        "- **提供形態**は `/screenNNN` が実際に表示する Widget（`ci/numbered_routes.toml`、CI で実行時の観測と照合）。"
        "**実装証跡**はパターンのディレクトリ内のコードの分類で、旧 `view.dart` はアプリから到達しない。",
        *([f"- 提供形態: {_counts(summary['provisions'])} / 旧 view.dart: {_counts(summary['legacy_views'])}"]
          if summary.get("provisions") else []),
        "",
        "| ID | パターン | 提供形態（route） | 実装証跡 | 完成度（保守的判定） | 責務 | Dart数 | producer / 次の課題 |",
        "|---:|---|---|---|---|---|---:|---|",
    ]
    for row in sorted(records, key=lambda r: r["id"]):
        prod = row.get("producer")
        evidence = prod["source"] if prod else "Flutter実操作/処理の追加検証"
        if prod and not prod.get("flutter_runtime_connected", False):
            evidence += "（Flutter未接続）"
        lines.append("| " + " | ".join([
            f"{row['id']:03d}", escape(row["name"]),
            escape(f"{row['provision']}（{row['route']}）" if row.get("route") else "—"),
            escape(row["status"]),
            completion(row), escape(row["target_owner"]), str(len(row["dart_files"])),
            escape(evidence),
        ]) + " |")
    lines.extend(["", "## 今後の判断基準", "",
        "1. Pythonを優先し、非同期・ブラウザ固有の処理はJS/Node/Denoを検討。Dartは必要なView・ネイティブ処理に限定する。",
        "2. Dartの縮小を明確な目標としつつ、機能や実操作を失う削除はしない。",
        "3. 旧Controller/Service/Modelの参照と旧テストを確認し、実機能・CI・JUnitで保証する。",
        "4. 削減した本番Dart/テストDart数、増えた実機能、テスト成否、残課題を変更ごとに記録する。",
        "5. 本表の状態は証跡に基づく暫定値。完全実装は独立した機能契約・実操作・テストで確認したときだけ認定する.",
        ""])
    return "\n".join(lines)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("inventory", type=Path)
    p.add_argument("output", type=Path)
    p.add_argument("--head", required=True, help="PR head SHA the report is about")
    p.add_argument("--tree", help="checked-out commit, when it differs (pull_request merge ref)")
    args = p.parse_args()
    report = json.loads(args.inventory.read_text(encoding="utf-8"))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(render(report, args.head, args.tree), encoding="utf-8")


if __name__ == "__main__":
    main()
