# 课时2：核心游戏逻辑实现

## 课时目标
- 掌握Godot场景搭建和节点使用
- 学会程序化美术资源创建
- 实现贪吃蛇的核心移动逻辑
- 完成碰撞检测和游戏状态管理

## 教学内容

### 1. 场景搭建与美术资源（8分钟）

#### Godot自绘技术方案
```mermaid
graph TD
    A[美术资源需求] --> B{资源类型}
    B -->|几何图形| C[Polygon2D]
    B -->|纯色方块| D[ColorRect]
    B -->|线条装饰| E[Line2D]
    B -->|粒子效果| F[Particles2D]
    
    C --> G[蛇头三角形]
    C --> H[食物圆形]
    D --> I[蛇身方块]
    D --> J[游戏背景]
    E --> K[网格线]
    F --> L[食物特效]
```

#### 视觉设计系统
```mermaid
graph LR
    A[设计系统] --> B[色彩规范]
    A --> C[尺寸规范]
    A --> D[动画规范]
    
    B --> B1[主色调: #27AE60]
    B --> B2[辅助色: #E74C3C]
    B --> B3[背景色: #2C3E50]
    B --> B4[文字色: #FFFFFF]
    
    C --> C1[网格大小: 20px]
    C --> C2[蛇身大小: 18px]
    C --> C3[食物大小: 16px]
    
    D --> D1[移动: 线性插值]
    D --> D2[生长: 缩放动画]
    D --> D3[死亡: 闪烁效果]
```

#### 响应式布局设计
```mermaid
graph TB
    A[游戏界面 1024x768] --> B[游戏区域 800x600]
    A --> C[UI区域 224x768]
    
    B --> B1[网格 40x30]
    B --> B2[边界检测区域]
    
    C --> C1[分数显示]
    C --> C2[控制按钮]
    C --> C3[游戏信息]
    
    style A fill:#2C3E50
    style B fill:#34495E
    style C fill:#95A5A6
```

### 2. 游戏核心逻辑（15分钟）

#### 蛇的数据结构对比
```mermaid
graph TB
    A[蛇身表示方案] --> B[数组方案]
    A --> C[链表方案]
    
    B --> B1[优点: 随机访问O1]
    B --> B2[优点: 内存连续]
    B --> B3[缺点: 插入删除On]
    
    C --> C1[优点: 插入删除O1]
    C --> C2[缺点: 随机访问On]
    C --> C3[缺点: 内存不连续]
    
    D[选择: 数组方案] --> E[理由: 蛇身访问频繁]
    D --> F[理由: GDScript数组优化好]
```

#### 移动算法流程
```mermaid
sequenceDiagram
    participant Input as 输入系统
    participant Snake as 蛇控制器
    participant Grid as 网格系统
    participant Collision as 碰撞检测
    
    Input->>Snake: 方向改变
    Snake->>Snake: 验证方向有效性
    Snake->>Grid: 计算新头部位置
    Snake->>Collision: 检测碰撞
    
    alt 无碰撞
        Snake->>Snake: 添加新头部
        Snake->>Snake: 移除尾部
    else 碰撞食物
        Snake->>Snake: 添加新头部
        Snake->>Snake: 保留尾部(增长)
    else 碰撞障碍
        Snake->>Snake: 触发游戏结束
    end
```

#### 碰撞检测系统
```mermaid
graph TD
    A[碰撞检测] --> B[边界碰撞]
    A --> C[自身碰撞]
    A --> D[食物碰撞]
    
    B --> B1{头部X < 0}
    B --> B2{头部X >= 宽度}
    B --> B3{头部Y < 0}
    B --> B4{头部Y >= 高度}
    
    C --> C1[遍历蛇身]
    C --> C2[比较头部位置]
    
    D --> D1[位置重叠检测]
    D --> D2[触发食物消失]
    D --> D3[生成新食物]
    
    B1 --> E[游戏结束]
    B2 --> E
    B3 --> E
    B4 --> E
    C2 --> E
    
    D1 --> F[分数增加]
    D2 --> F
    D3 --> F
```

#### 食物生成算法
```mermaid
graph TD
    A[生成新食物] --> B[随机位置生成]
    B --> C{位置是否被占用}
    C -->|是| D[重新生成位置]
    C -->|否| E[确认食物位置]
    D --> C
    E --> F[创建食物对象]
    F --> G[添加到场景]
    
    H[优化策略] --> I[预计算可用位置]
    I --> J[从可用位置中随机选择]
    J --> K[更新可用位置列表]
```

### 3. 状态管理（7分钟）

#### 游戏状态机
```mermaid
stateDiagram-v2
    [*] --> Menu: 启动游戏
    Menu --> Playing: 开始游戏
    Playing --> Paused: 暂停
    Paused --> Playing: 继续
    Playing --> GameOver: 碰撞死亡
    GameOver --> Menu: 返回菜单
    GameOver --> Playing: 重新开始
    
    Playing --> Playing: 正常移动
    Playing --> Playing: 吃到食物
```

#### 分数系统设计
```mermaid
graph LR
    A[分数计算] --> B[基础分数]
    A --> C[连击奖励]
    A --> D[速度奖励]
    A --> E[长度奖励]
    
    B --> B1[每个食物: 10分]
    C --> C1[连续吃食物: x1.2]
    D --> D1[高速度: +5分]
    E --> E1[长度每10: +50分]
    
    F[最终分数] --> G[基础分数 × 连击倍数 + 奖励分数]
```

#### 难度递增机制
```mermaid
graph TD
    A[难度系统] --> B[速度递增]
    A --> C[食物类型]
    A --> D[障碍物]
    
    B --> B1[每10分: 速度+5%]
    B --> B2[最大速度限制]
    
    C --> C1[普通食物: 10分]
    C --> C2[特殊食物: 20分]
    C --> C3[负面食物: -5分]
    
    D --> D1[固定障碍物]
    D --> D2[移动障碍物]
```

## 实践环节

### 1. 场景节点结构
```
Main (Node2D)
├── Background (ColorRect)
├── GameArea (Node2D)
│   ├── Snake (Node2D)
│   │   ├── Head (Polygon2D)
│   │   └── Body (Node2D)
│   │       ├── Segment1 (ColorRect)
│   │       ├── Segment2 (ColorRect)
│   │       └── ...
│   ├── Food (Node2D)
│   │   ├── Shape (Polygon2D)
│   │   └── Effect (Particles2D)
│   └── Grid (Node2D)
└── UI (CanvasLayer)
    ├── Score (Label)
    ├── Level (Label)
    └── Controls (VBoxContainer)
```

### 2. 核心脚本结构

#### Snake.gd 核心逻辑
```gdscript
# 主要属性
var body: Array[Vector2] = []
var direction: Vector2 = Vector2.RIGHT
var grid_size: int = 20
var is_growing: bool = false

# 主要方法
func move() -> void
func grow() -> void
func check_collision() -> CollisionType
func change_direction(new_direction: Vector2) -> void
```

#### GameManager.gd 游戏管理
```gdscript
# 游戏状态
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }
var current_state: GameState = GameState.MENU

# 游戏数据
var score: int = 0
var level: int = 1
var game_speed: float = 1.0

# 主要方法
func start_game() -> void
func update_game(delta: float) -> void
func end_game() -> void
```

### 3. 实现步骤

1. **创建基础场景结构**
   - 设置游戏区域和UI布局
   - 创建网格背景
   - 配置摄像机和视口

2. **实现蛇的移动逻辑**
   - 初始化蛇身数组
   - 实现移动算法
   - 添加方向控制

3. **添加碰撞检测**
   - 边界检测
   - 自身碰撞检测
   - 食物碰撞检测

4. **完成食物系统**
   - 随机生成食物
   - 食物消失逻辑
   - 分数计算

## 技术要点

### 1. 性能优化
- 使用对象池管理蛇身段
- 限制碰撞检测频率
- 优化渲染调用

### 2. 代码规范
- 统一命名约定
- 适当的注释
- 模块化设计

### 3. 调试技巧
- 使用print()输出调试信息
- 利用Godot调试器
- 可视化碰撞区域

## 课时总结

本课时通过实际编码，学生掌握了：
1. Godot场景系统的使用方法
2. 游戏循环和状态管理
3. 碰撞检测的实现原理
4. 程序化美术资源创建

## 作业布置

1. 优化蛇的移动动画效果
2. 添加更多类型的食物
3. 实现简单的粒子效果

## 下节课预告

下节课我们将实现游戏AI系统，让电脑也能玩贪吃蛇，并学习基础的AI算法在游戏中的应用。