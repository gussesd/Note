##  3/22/2024  => 周

TAPD   ID1004471
解决优化群组npc队列行走过程中重合在一起的问题
解决在随机时间时对于接近的两个时间点进行偏移。
TAPD ID1004434
多人额外行为的的单独配置需求
	目前完成了C#对于界面相应的修改,以及对cfg配置表的调整
	后续需要对Lua部分的行为逻辑进行修改


C# 部分已经完成,反向读取需要测试,通过后进行lua书写

## 3/29/2024  => 周


1. 多人额外行为的的单独配置初版,完成后续进一步优化
2. 对第一个点的编辑进行调整(1.调整点大小, 2.  )
3. 获取组群是获取方案的调整
4. 终点人物重合问题修正

## 4/3/2024 => 周
1. 继续完善多人交互的行为路径
2. 修改侧边栏,切换路线后自动保存
	1. 及时退出编辑状态,解决点不动,状态退出不了,以及各种意外行为
	2. 给予相应的提示,指出当下的问题


## 4/12/2024  =>周

1. 整合两块路径行为,使功能合并,简化
2. 一键将点附着在表面
3. 修改表结构,合并4份配置为一份

## 4/19/2024  =>周
1. 编辑器功能优化调整
2. 路径逻辑修改调整
3. 气泡逻辑单独迁出,不走NPC逻辑
4. 任务之间黑幕衔接问题
 注: 策划忙于主线 , 需要月底才有空使用行为路径.

## 4/26/2024  =>周
1. 添加黑幕手动控制, 超时隐藏
2. 编辑器功能优化
3. 奥斯卡找不同玩法, 进行中
## 4/30/2024  =>周
1. 奥斯卡找不同玩法

## 5/11/2024  =>周
1. 奥斯卡的心意调整
2. 虚拟相机参数添加
3. 邀约对话退出按钮
4. 一些bug修正

## 5/17/2024 =>周
1. npc行为的组优化
2. 一些bug修正

## 5/24/2024 =>周
1. 编组行为拓展
2. 次要npc移动动画优化
3. 一些bug修正 (Animation , UI)
## 5/31/2024 =>周
1. npc编辑器功能添加/修改
2. npc移动逻辑修改
3. 一些bug修正

## 6/7/2024 => 周
1. [1442]怪物血条与倒计时UI位置冲突
2. [239]礼物获得跳转
3. bug修正 [任务界面优化, 追击敌人不动]

## 6/14/2024 => 周
1. 布点编辑器功能修改和优化
2. NPC对话框特效
3. 礼物墙特效
4. NPC视野维护

目前大概总结一下 提出的问题
1. 集中在Unity编辑器不好用,具体描述是打开慢,经常有报错启动不了
2. 改了实现方式,布点数量增加感觉更麻烦
	1. 之前是以一条线为根,然后向里面添加任意数量的NPC
	2. 现在是按照讨论时说的用拼积木的想法,[路线依赖于NPC, 一个NPC唯一对应一条线],做上面流水线的NPC时需要添加很多线 , 做各种特殊复杂逻辑的时候会更好

3. 还有些操作上的习惯问题吧 , 感觉是需要适应

## 6/21/2024 => 周
1. NPC对话框增加动特效[1547]
2. 礼物墙特效不对修正[1616]
3. 背包自选宝箱逻辑调整[1766]
4. 多原材料合成加工品放入和数量调整统一[1686]
5. 炼药，炼金，合成，分解优化[1786]
6. npc特殊移动方案增加
7. 一些bug修正 [路点贴合地形 , 通用老人动画修改]

## 6/27/2024 => 周
1. 炼药无需求限制 [1466]
2. 生活类技能添加动画[1815]
3. 多原材料合成加工品通用icon[1820]
4. 查看他人礼物墙优化[1817]
5. 豪爽等级界面问题[1853]
6. 魂骨添加部位筛选[1802]
7. 其他预制体, bug的修正


## 7/5/2024 =>周
1.  收礼界面新/红点提示, 礼物墙优化[239]
2. 多原材料烹饪配方,自动停止放入材料[1898]
3. 奥斯卡找不同,添加提示点[2063]
4. 添加全部年限选择[2071]
5. 坐骑技能恢复缓慢进度条, 非跳变的[2035]
6. 其他细节修正

## 7/12/2024 =>周
1. 多处赠礼入口调整优化[2146]
2. 魂骨部位筛选调整[1802]
3. 合成物品时新物品弹窗[2107]
4. 礼物墙位置偏移[2128]
5. 聊天框快捷键切换响应调整[2193]
6. 组队添加一个发布于世界的喊话[2022]
7. 其他: 悬赏任务接取后放置最后

## 7/19/2024 =>周
1. 大小框里选中的材料发出去的逻辑不互通[2215]
2. 好友私聊功能问题[2229]
3. 合成解锁条件添加爵位勋章等级解锁[2265]
4. 切换好友私聊框有异常新消息提醒[2317] 
5. 炼药,烹饪,炼金,铸造添加动画音效[2321]
6. 合成解锁条件添加爵位勋章等级解锁[2265]
7. 对话,钓鱼等事件接入"F"多列表
8. 随机宝箱和普遍宝箱不显示高亮显示框
9. 其他bug修正,
	1. 小窗口,历史聊天, 
	2. 伙伴页面,表情重复问题, 
	3. 点击材料后聊天窗输入未归位


## 7/26/2024 =>周
1. 聊天中申请入队时，判断下是否满足队伍条件[2383]
2.  聊天界面优化(表情,对话聊天,好友消息,道具图文)[246]
3. 采集对话等交互时关闭缩放[2439]
4. 其他内容修正(交互名称,采集交互)
## 8/2/2024 =>周
1. 聊天栏, 简易聊天栏,字色区分[2601]
2.  气泡聊天框资源效果调整[2592]
3. 生活类天赋资源动画调整

## 8/9/2024 =>周
1. 聊天框赞助豪爽标识资源替换[2814]
2. 前端压力工具功能扩展,移动和技能[2757]
3. 装备分解展示优化[2806]
4. 组队 , 聊天 , 生活技能 , 交互等显示效果和逻辑修改


## 8/16/2024 =>周
1. 学院赞助徽章[3009]
2. 动态表情聊天框显示问题,聊天界面UI调整 [3018,3028] , [2920]
3. 赞助tipsUI,动画调整[3045]
4. UnitLoadManager功能优化[2757]
5. 其他bug修正
	1. 修正动画效果[2806]
	2. 好友点击响应(PersonalHSTipNode)


## 8/23/2024 =>周
1. 送礼记录获取方式调整[3300]
2. 奥斯卡心意修改[3235]
3. 一些UI的调整
4. SDK接入

## 8/30/2024 =>周
1. 学院赞助获得弹窗背后增加背景模糊功能[3454]
2. 聊天主界面表情规范[3575]
3. 附近频道聊天时，发言角色的头上显示文字气泡和聊天内容[3497]
4. SDK接入 , 登录模块调整 , 炼药问题查看

## 9/6/2024 =>周
1. 使用配方后，飘字提示[3629]
2. 背景图范围稍稍拉大,扩大空白处的点击区域[3722]
3. 聊天校验规范修正[3599]
4. 频道红包功能[2804]
5. 其他
	1. 聊天头像框添加背景
	2. 预制体文字引用 TMP字体 (扩大文字容量)
	3. 内外网平台判断设置, 平台可通过C#,ServerList

## 9/14/2024 =>周
1. 频道红包功能[2804]
2.  烹饪界面，配方问题[3772]
3. 做一个宏开关，可以开启和关闭贪玩sdk流程,打包前预处理 [3565]
4. 频道红包排序问题[3971] 
5. 生活技能界面细节优化[3958]
6. 其他
	1. 登录数据处理
	2.  服务器列表改为json[3443]
	3. 快捷聊天显示BUG[3965]
	4. 其他细小bug修正

## 9/20/2024 =>周
1.  后台看板数据对接支持[3530]
2.  打包前预处理[3565]
3. 添加游戏内打开系统相册
4. 其他
	1.  红包bug修正, 效果图修改[3235]
	2. 添加READ_EXTERNAL_STORAGE权限
