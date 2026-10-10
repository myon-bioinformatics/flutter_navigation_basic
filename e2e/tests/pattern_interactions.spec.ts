import {test,expect,Page} from '@playwright/test';
import {waitForFlutter} from '../utils/helpers';

// These routes are enabled only in flutter build --dart-define=E2E=true.
// /screen171 etc instead render GenericScreen and cannot validate this widget.
async function openInteraction(page:Page,id:number) {
  await page.goto('/#/examples/data-processing-interactions/'+id);
  await waitForFlutter(page);
  await expect(page.getByText('Pattern '+id+':',{exact:false})).toBeVisible();
  await expect(page.getByText('順序: A, B, C')).toBeVisible();
}
async function pointerDrag(page:Page, from:string,to:string,holdMs=0) {
  const a=page.locator('[flt-semantics-identifier="interaction-item-'+from+'"]');
  const b=page.locator('[flt-semantics-identifier="interaction-item-'+to+'"]');
  await expect(a).toHaveCount(1);
  await expect(b).toHaveCount(1);
  const start=await a.boundingBox();
  const end=await b.boundingBox();
  if(!start||!end)throw new Error('Missing draggable item bounds');
  const x=start.x+start.width/2,y=start.y+start.height/2;
  await page.mouse.move(x,y);
  await page.mouse.down();
  if(holdMs)await page.waitForTimeout(holdMs);
  await page.mouse.move(end.x+end.width/2,end.y+end.height*0.85,{steps:20});
  await page.mouse.up();
}
test('171 pointer reorders Flutter list @gesture',async({page})=>{
  await openInteraction(page,171);
  await pointerDrag(page,'A','C');
  await expect(page.getByText('順序: A, B, C')).not.toBeVisible();
});
test('172 ReorderableListView can be driven by external mouse @gesture',async({page})=>{
  await openInteraction(page,172);
  await pointerDrag(page,'A','C');
  await expect(page.getByText('順序: A, B, C')).not.toBeVisible();
});
test('173 grid drag-and-drop is a native gesture @gesture',async({page})=>{
  await openInteraction(page,173);
  await pointerDrag(page,'A','B',700);
  await expect(page.getByText('順序: B, A, C')).toBeVisible();
});
test('174 animated insertion is externally operable @portable',async({page})=>{
  await openInteraction(page,174);
  await page.getByRole('button',{name:'挿入'}).click();
  await expect(page.getByText('順序: N1, A, B, C')).toBeVisible();
  await expect(page.getByText('N1',{exact:true})).toBeVisible();
});
test('175 animated removal is externally operable @portable',async({page})=>{
  await openInteraction(page,175);
  await page.getByRole('button',{name:'削除',exact:true}).click();
  await expect(page.getByText('順序: B, C')).toBeVisible();
});
test('183 selection and batch deletion are externally operable @portable',async({page})=>{
  await openInteraction(page,183);
  await page.getByText('A',{exact:true}).click();
  await expect(page.getByText('選択数: 1')).toBeVisible();
  await page.getByRole('button',{name:'選択項目を削除'}).click();
  await expect(page.getByText('順序: B, C')).toBeVisible();
});
test('184 long-press list drag is externally operable @gesture',async({page})=>{
  await openInteraction(page,184);
  await pointerDrag(page,'A','C',700);
  await expect(page.getByText('順序: A, B, C')).not.toBeVisible();
});
