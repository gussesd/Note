
* _npcBases  npc base 表数据内容
* 首点编辑处理方案,坐标点放大至1.1
* 首点编辑由于外部有个GizmoAxis 导致的重合以至于点不到内部的GizmoAxis
* 解决方案
	1.隐藏外部的GizmoAxis
	2.偏移外部的GizmoAxis 使得两者不再重合