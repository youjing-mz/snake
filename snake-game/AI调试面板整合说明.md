# AI调试面板整合说明

## 整合目标

将原本分离的 `AIDebugPanel.gd` 和 `AIDebugVisualizer.gd` 整合为一个统一的AI调试面板，避免功能重复，提供更好的用户体验。

## 整合内容

### 1. 统一调试面板 (AIDebugPanel.gd)

**功能特性：**
- 调试信息显示：决策信息、性能指标、行为分析、风险评估、路径信息
- 可视化功能：路径绘制、安全区域显示、决策箭头、思考指示器
- 交互控制：显示开关、自动暂停、单步执行
- 数据管理：指标记录、历史跟踪、数据导出

**主要组件：**
- 信息面板：RichTextLabel显示详细调试信息
- 可视化层：Node2D绘制路径、区域、箭头等
- 控制面板：CheckBox和Button提供交互控制
- 数据存储：Dictionary管理指标和行为数据

### 2. 删除的重复组件

**AIDebugVisualizer.gd：**
- 已删除，功能完全整合到AIDebugPanel中
- 可视化绘制逻辑移至AIDebugPanel的可视化方法中
- 信号连接和数据处理统一管理

### 3. 更新的相关文件

**GameUI.gd：**
- 简化AI调试面板创建，使用统一的AIDebugPanel
- 删除重复的UI创建和信号处理代码
- 保留调试设置变化处理接口

**Game.gd：**
- 移除AIDebugVisualizer相关引用和创建代码
- 更新可视化选项设置，通过统一面板处理
- 修复快捷键切换，使用调试面板的toggle方法

**AITestRunner.gd：**
- 修复内存使用函数调用（get_static_memory_usage）
- 保持对AIDebugPanel的引用

## 使用方法

### 1. 启用调试面板

```gdscript
# 在GameUI中
if ai_debug_enabled:
    _create_ai_debug_panel()
    _connect_ai_debug_panel()
```

### 2. 连接AI系统

```gdscript
# 设置AI玩家引用
ai_debug_panel.set_ai_player(ai_player)

# 添加可视化层到游戏场景
ai_debug_panel.add_visualization_to_scene(game_scene)

# 启用调试显示
ai_debug_panel.toggle_debug_display()
```

### 3. 接收调试数据

调试面板会自动连接AI系统的调试信号：
- `decision_made`: 决策信息更新
- `performance_updated`: 性能指标更新
- `behavior_analyzed`: 行为分析更新
- `risk_assessed`: 风险评估更新
- `path_calculated`: 路径信息更新

### 4. 控制可视化选项

用户可以通过面板上的控制选项：
- 显示/隐藏路径：绘制AI的移动路径
- 显示/隐藏风险区域：标记安全和危险区域
- 显示/隐藏思考过程：显示AI思考指示器
- 自动暂停：高风险时自动暂停游戏
- 单步执行：逐步执行AI决策

## 优势

1. **功能统一**：调试信息和可视化在一个面板中管理
2. **减少重复**：避免多个组件处理相同功能
3. **性能优化**：减少节点数量和信号连接
4. **易于维护**：单一组件便于调试和更新
5. **用户友好**：统一的操作界面和控制方式

## 测试验证

使用 `test_debug_panel.gd` 或 `simple_test.gd` 启动游戏并验证：
- 调试面板正确显示
- AI决策信息实时更新
- 可视化元素正确绘制
- 控制选项正常工作
- 性能指标准确记录

## 注意事项

1. 确保在GameUI初始化时正确创建和连接调试面板
2. AI系统的调试信号需要正确发送数据
3. 可视化层需要正确添加到游戏场景的合适位置
4. 内存和性能监控要适度，避免影响游戏性能

通过这次整合，AI调试功能变得更加统一和高效，为开发者提供了更好的调试体验。 