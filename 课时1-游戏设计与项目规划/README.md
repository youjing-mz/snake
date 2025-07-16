# 课时1：游戏设计与项目规划

## 课时目标
- 理解游戏开发的完整流程
- 掌握项目规划和架构设计方法
- 学会使用Godot引擎的基础概念
- 完成贪吃蛇游戏的整体设计

## 教学内容

### 1. 游戏开发流程介绍（8分钟）

#### 现代游戏开发流程
```mermaid
graph TD
    A[需求分析] --> B[概念设计]
    B --> C[技术选型]
    C --> D[原型开发]
    D --> E[迭代开发]
    E --> F[测试优化]
    F --> G[发布部署]
    G --> H[运营维护]
    
    E --> D
    F --> E
```

#### 敏捷开发在游戏项目中的应用
- **迭代周期**：1-2周为一个Sprint
- **可玩原型**：每个迭代都要有可测试的版本
- **持续反馈**：及时调整设计和实现
- **版本控制**：Git工作流的重要性

### 2. 贪吃蛇游戏设计（12分钟）

#### 游戏核心循环分析
```mermaid
graph LR
    A[玩家输入] --> B[蛇移动]
    B --> C[碰撞检测]
    C --> D{碰撞类型}
    D -->|食物| E[增长+得分]
    D -->|墙壁/自身| F[游戏结束]
    D -->|无碰撞| G[继续移动]
    E --> H[生成新食物]
    H --> A
    G --> A
    F --> I[显示结果]
```

#### 功能模块划分
```mermaid
graph TB
    A[贪吃蛇游戏] --> B[核心游戏逻辑]
    A --> C[渲染系统]
    A --> D[输入处理]
    A --> E[UI界面]
    A --> F[音效系统]
    A --> G[数据管理]
    
    B --> B1[蛇移动逻辑]
    B --> B2[碰撞检测]
    B --> B3[食物生成]
    B --> B4[游戏状态]
    
    C --> C1[蛇身渲染]
    C --> C2[食物渲染]
    C --> C3[背景渲染]
    
    D --> D1[键盘输入]
    D --> D2[触摸输入]
    
    E --> E1[主菜单]
    E --> E2[游戏界面]
    E --> E3[设置界面]
    
    G --> G1[分数记录]
    G --> G2[设置保存]
```

#### 技术架构设计
```mermaid
graph TB
    subgraph "客户端 (Godot)"
        A[主场景 Main]
        B[游戏场景 Game]
        C[菜单场景 Menu]
        D[设置场景 Settings]
        
        E[游戏管理器 GameManager]
        F[蛇控制器 Snake]
        G[食物管理器 Food]
        H[输入处理器 InputHandler]
        I[UI管理器 UIManager]
    end
    
    subgraph "服务端 (Golang)"
        J[HTTP服务器]
        K[WebSocket服务器]
        L[游戏房间管理]
        M[玩家数据管理]
        N[排行榜系统]
    end
    
    A --> B
    A --> C
    A --> D
    B --> E
    E --> F
    E --> G
    E --> H
    E --> I
    
    I -.->|网络通信| K
    E -.->|数据同步| L
```

#### 数据结构设计
```mermaid
classDiagram
    class Snake {
        +Array~Vector2~ body
        +Vector2 direction
        +int length
        +bool is_growing
        +move()
        +grow()
        +check_collision()
    }
    
    class Food {
        +Vector2 position
        +int value
        +String type
        +spawn_random()
        +is_eaten()
    }
    
    class GameState {
        +int score
        +int level
        +bool is_paused
        +bool is_game_over
        +float game_speed
        +update()
        +reset()
    }
    
    class GameManager {
        +Snake snake
        +Food food
        +GameState state
        +start_game()
        +update_game()
        +end_game()
    }
    
    GameManager --> Snake
    GameManager --> Food
    GameManager --> GameState
```

### 3. Godot引擎介绍（10分钟）

#### 节点树概念
```mermaid
graph TD
    A[Main 主节点] --> B[UI层 CanvasLayer]
    A --> C[游戏层 Node2D]
    
    B --> B1[分数显示 Label]
    B --> B2[暂停按钮 Button]
    B --> B3[游戏结束界面 Control]
    
    C --> C1[蛇 Snake]
    C --> C2[食物 Food]
    C --> C3[背景 Background]
    
    C1 --> C1A[蛇头 Polygon2D]
    C1 --> C1B[蛇身段1 ColorRect]
    C1 --> C1C[蛇身段2 ColorRect]
    
    C2 --> C2A[食物图形 Polygon2D]
    C2 --> C2B[食物特效 Particles2D]
```

#### GDScript语言特点
- **Python风格语法**：缩进敏感，易于阅读
- **动态类型**：灵活的变量声明
- **信号系统**：事件驱动编程
- **节点访问**：便捷的场景树操作

#### 信号系统（观察者模式）
```mermaid
sequenceDiagram
    participant Snake
    participant GameManager
    participant UI
    participant Food
    
    Snake->>GameManager: food_eaten信号
    GameManager->>UI: update_score信号
    GameManager->>Food: spawn_new信号
    
    Snake->>GameManager: game_over信号
    GameManager->>UI: show_game_over信号
```

## 实践环节

### 1. 创建项目结构
```
snake-game/
├── project.godot
├── scenes/
│   ├── Main.tscn
│   ├── Game.tscn
│   ├── Menu.tscn
│   └── GameOver.tscn
├── scripts/
│   ├── GameManager.gd
│   ├── Snake.gd
│   ├── Food.gd
│   └── InputHandler.gd
├── assets/
│   └── fonts/
└── docs/
    ├── design.md
    └── api.md
```

### 2. 设计游戏界面原型
- **主菜单界面**：开始游戏、设置、退出
- **游戏界面**：游戏区域、分数显示、暂停按钮
- **游戏结束界面**：最终分数、重新开始、返回菜单

### 3. 编写技术设计文档
- **游戏设计文档**：玩法规则、功能需求
- **技术架构文档**：模块划分、接口设计
- **开发计划**：任务分解、时间安排

## 课时总结

本课时通过系统性的设计方法，让学生理解：
1. 游戏开发不仅仅是编程，更是系统工程
2. 良好的设计是成功项目的基础
3. 模块化思维在复杂项目中的重要性
4. 文档驱动开发的价值

## 作业布置

1. 完善游戏设计文档，添加更多细节
2. 研究Godot官方文档中的2D游戏示例
3. 思考如何为贪吃蛇游戏添加创新元素

## 下节课预告

下节课我们将开始实际的编码工作，实现贪吃蛇的核心游戏逻辑，包括蛇的移动、食物生成和碰撞检测。