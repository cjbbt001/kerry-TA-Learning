# Kerry TA Learning

Unity Technical Art 学习项目，围绕角色渲染、基础光照与环境映射，使用 ShaderLab / HLSL 实现并验证常见实时渲染技术。

## 效果展示

<p align="center">
  <img src="Assets/environment-mapping/Screenshots/jade_left.png" width="49%" alt="玉石材质效果一">
  <img src="Assets/environment-mapping/Screenshots/jade_right.png" width="49%" alt="玉石材质效果二">
</p>

| Image-Based Lighting | Spherical Harmonics | Reflection Probe |
| :---: | :---: | :---: |
| ![IBL](Assets/environment-mapping/Screenshots/IBL.png) | ![SH](Assets/environment-mapping/Screenshots/SH.png) | ![Reflection Probe](Assets/environment-mapping/Screenshots/ReflectionProbe.png) |

## 技术内容

### 角色渲染

- Composite Mask 材质分区与 Skin LUT 皮肤近似
- TBN 法线映射、简化 Blinn-Phong 高光与 Cubemap IBL
- 二阶球谐环境光与双层各向异性头发高光
- 实时阴影、光照衰减、Linear Color Space 与 ACES Tone Mapping

### 基础光照

- Blinn-Phong 漫反射与镜面反射
- AO、Specular Mask、Normal Map 与 Parallax Mapping
- ForwardBase 阴影接收及 ForwardAdd 多光源叠加

### 环境映射与玉石材质

- Cubemap、HDR 解码与基于 Roughness 的 Mipmap 采样
- Diffuse / Specular IBL、Reflection Probe 与 Light Probe
- 二阶 Spherical Harmonics 环境光
- Thickness Map 背光透射、Fresnel 与多光源透射叠加

## 环境

- Unity `6000.3.16f1`
- Built-in Render Pipeline
- ShaderLab / HLSL
