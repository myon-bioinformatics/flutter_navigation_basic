'use strict';
const base=require('./playwright.config.cjs');
const selection=require('./proof-selection.json');
const expected=['/screen136','/screen39','/screen5','/examples/external-integration/mcp'];
if(selection.schema!=='flutter-proof-selection/1'||selection.caseCount!==8||JSON.stringify(selection.routes)!==JSON.stringify(expected)||selection.retries!==0||selection.workers!==2)throw Error('Explicit eight-case proof discovery selection required');
const escape=value=>value.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
if(selection.liveExecutionEnabled!==true||process.env.AUDIT_PROOF_DISCOVERY!=='1')throw Error('Explicit new proof-discovery mode required');
module.exports={...base,grep:new RegExp('observe public route ('+selection.routes.map(escape).join('|')+')$')};
