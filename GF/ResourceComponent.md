ResourceComponent 资源组件
和Entity组件类似
- 管理这资源相关内容
- 初始化资源管理器 ResourceManger
- ResourceManger
	- 初始化资源(InitResources),通过路径(m_ReadOnlyPath)加载资源信息
	- 资源管理器,管理所有的资源信息(注意只是资源信息,并没有加载实际的资源)
	- 控制资源信息的更新获取以及版本数据等
	- 处理各个资源组数据