# 架构依赖图
# ------------------
# 无依赖：constants, utils
# 数据层：data
# 核心层：core (仅依赖数据层)
# 组件层：components (仅依赖核心层)
# 实体层：entities (依赖组件层、核心层)
# 世界层：world (依赖实体层)
# 系统层：systems (依赖世界层、核心层)
# UI层：ui (仅依赖系统层、数据层)
# 场景层：scenes (依赖所有底层)

