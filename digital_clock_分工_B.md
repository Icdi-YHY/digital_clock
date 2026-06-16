# 工程师 B — 寄存器与辅助信号工程师

## 职责
内部寄存器声明、按键消抖/边缘检测、闪烁信号生成。

## 负责代码

### 寄存器声明

| 行号 | 代码 |
|------|------|
| 22 | `reg [3:0] s_l, s_h;` |
| 23 | `reg [3:0] m_l, m_h;` |
| 24 | `reg [3:0] h_l, h_h;` |
| 26 | `reg [3:0] am_l, am_h;` |
| 27 | `reg [3:0] ah_l, ah_h;` |
| 29 | `reg key_prev;` |
| 30 | `wire ke;` |
| 31 | `reg blk;` |
| 32 | `reg alm;` |

### 按键消抖与边缘检测

| 行号 | 代码 |
|------|------|
| 38 | `always @(posedge clk or posedge rst) begin` |
| 39 | `if(rst) key_prev <= 1'b0;` |
| 40 | `else key_prev <= key_add;` |
| 41 | `end` |
| 42 | `assign ke = (key_add && !key_prev);` |

### 闪烁信号生成

| 行号 | 代码 |
|------|------|
| 45 | `always @(posedge clk or posedge rst) begin` |
| 46 | `if(rst) blk <= 1'b0;` |
| 47 | `else blk <= ~blk;` |
| 48 | `end` |

## 工作量
- **行数**: ~20 行
- **占比**: ~13%
- **关键贡献**: 按键边缘检测（ke）、闪烁时钟（blk）、所有内部寄存器定义
