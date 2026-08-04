# Kerry TA Learning

基于 Unity Built-in Render Pipeline 的 Technical Art 学习项目，集中记录三个实时渲染练习：自定义 Blinn-Phong 光照、环境映射与玉石材质、轻量级角色渲染。项目主要使用 ShaderLab / HLSL，从基础直接光照逐步扩展到法线映射、多光源、IBL、球谐环境光、皮肤近似和各向异性头发高光。

## Mobile Character Rendering

使用 Body 与 Hair 两个手写 `ForwardBase` Shader，组合材质分区、皮肤明暗近似、环境光照和双层各向异性头发高光。

![角色正面](Assets/MobileCharacterRendering/Screenshots/front.png)

| 头部与头发高光 | 背面效果 |
| :---: | :---: |
| ![头部特写](Assets/MobileCharacterRendering/Screenshots/head%20%282%29.png) | ![角色背面](Assets/MobileCharacterRendering/Screenshots/back.png) |

| 侧面头发高光 | 皮肤与金属细节 |
| :---: | :---: |
| ![侧面头发](Assets/MobileCharacterRendering/Screenshots/head%20%281%29.png) | ![腿部细节](Assets/MobileCharacterRendering/Screenshots/leg.png) |

![另一角度的头发高光](Assets/MobileCharacterRendering/Screenshots/head%20%283%29.png)

### Body Shader

- 使用 Composite Mask 的 R / G / B 通道分别控制粗糙度、金属度和皮肤区域，在同一材质中区分皮肤、服装与金属配件。
- 通过 TBN 矩阵将切线空间法线转换到世界空间，统一参与直接光、SH 与 Cubemap 反射计算。
- 普通区域使用 Lambert 漫反射；皮肤区域使用 Half-Lambert 查询 Skin LUT，近似明暗交界处的泛红与次表面散射质感。
- 使用 Roughness 控制简化 Blinn-Phong 直接高光，并为皮肤保留较弱的介质反射。
- 自定义二阶 SH 提供低频环境漫反射，Cubemap Mip 采样提供简化的环境镜面反射。

### Hair Shader

- Base Color 提供稳定底色，Normal Map 补充表面细节。
- Shift / Noise 贴图沿法线扰动副切线方向，使高光带产生不规则偏移。
- 基于切线、副切线与半程向量计算双层指数型各向异性高光，两层分别控制颜色、宽度、噪声和位置偏移。
- 根据 Roughness 选择 Cubemap Mip，为头发补充环境反射。

### 渲染与调试

- 主方向光支持实时阴影与衰减，最终颜色经过 ACES Tone Mapping。
- 工程使用 Linear Color Space，由 Unity 处理 sRGB 纹理输入与显示输出转换。
- Body 可分别开关 Diffuse、Specular、SH 和 IBL；Hair 可分别开关 Diffuse、Specular 和 IBL，便于逐模块排错。

> 该实现是面向学习和移动端思路的经验型方案，不是完整的 PBR 或物理头发模型。

## Blinn-Phong Lit Shader

从基础光照开始，逐步实现一个自定义 Built-in 管线材质 Shader，并在单体材质和小型场景中验证。

| 阶段 | 效果 |
| --- | --- |
| 基础光照：漫反射、镜面反射与环境光 | ![基础光照](Assets/lit%20shader/Screenshots/1_base.png) |
| Texture、AO 与 Specular Mask | ![贴图、AO 与高光遮罩](Assets/lit%20shader/Screenshots/2_texture.png) |
| TBN 法线映射 | ![法线映射](Assets/lit%20shader/Screenshots/3_normal.png) |
| 阴影接收与投射 | ![阴影](Assets/lit%20shader/Screenshots/4_shadow.png) |
| Parallax Mapping 与附加光源 | ![视差与附加光源](Assets/lit%20shader/Screenshots/5_prallax_lightadd.png) |
| 最终组合效果 | ![最终 Shader](Assets/lit%20shader/Screenshots/6_final.png) |

### 技术实现

- **Blinn-Phong**：使用法线、光照方向与半程向量计算漫反射和镜面反射，`Shininess` 控制高光锐利程度。
- **AO / Specular Mask**：分别控制遮蔽区域的明暗与镜面高光的可见范围。
- **Normal Map**：通过 TBN 将切线空间法线转换到世界空间，加入逐像素表面细节。
- **Parallax Mapping**：根据高度图与切线空间视线方向偏移 UV，形成近似深度效果。
- **Shadow**：`ForwardBase` 接收实时阴影，并通过 ShadowCaster 支持阴影投射。
- **ForwardAdd**：使用加法混合逐灯叠加额外实时光源，不重复计算环境光。

### 场景测试

![Blinn-Phong 场景测试](Assets/lit%20shader/Screenshots/house.png)

Tone Mapping、Gamma Correction 与 ACES 由后处理或渲染管线负责，不作为这一基础材质 Shader 的核心功能。

## Environment Mapping

从 Cubemap 环境反射出发，逐步练习 IBL、Spherical Harmonics、Reflection Probe 与 Light Probe，最后组合为玉石材质。

### Cubemap 与 Reflection Probe

- 使用世界空间视线与法线计算反射方向并采样 Cubemap。
- 使用 HDR 环境贴图保留高亮信息，并进行 HDR 解码。
- 加入 Normal Map 与 AO，丰富反射细节和结构层次。
- 使用 Reflection Probe 获取场景局部环境反射。

| 基础 Cubemap | Normal Map + AO | Reflection Probe |
| :---: | :---: | :---: |
| ![基础 Cubemap](Assets/environment-mapping/Screenshots/CubeMap.png) | ![法线与 AO](Assets/environment-mapping/Screenshots/CubeMap_AO%2BNormal.png) | ![Reflection Probe](Assets/environment-mapping/Screenshots/ReflectionProbe.png) |

### Image-Based Lighting

- **Specular IBL**：根据反射方向采样预过滤 Cubemap，并由 Roughness 控制 Mipmap 层级。
- **Diffuse IBL**：按法线方向获取低频环境颜色，近似环境漫反射。
- **Reflection Probe IBL**：使用 Unity 提供的局部 Probe 数据替代固定 Cubemap。

| Specular IBL | Diffuse IBL | Reflection Probe IBL |
| :---: | :---: | :---: |
| ![Specular IBL](Assets/environment-mapping/Screenshots/IBL.png) | ![Diffuse IBL](Assets/environment-mapping/Screenshots/IBL_Diffuse.png) | ![Reflection Probe IBL](Assets/environment-mapping/Screenshots/IBL_ReflectionProbe.png) |

### Spherical Harmonics 与 Light Probe

- 手动求值二阶 SH，理解 Unity 中低频环境光数据的组织与计算方式。
- Light Probe 在空间中保存烘焙后的 SH，使动态物体能够在探针间插值环境漫反射。
- Reflection Probe 主要提供高频镜面反射，Light Probe 主要提供低频漫反射光照。

| 二阶 Spherical Harmonics | Light Probe |
| :---: | :---: |
| ![手动球谐光照](Assets/environment-mapping/Screenshots/SH.png) | ![Unity Light Probe](Assets/environment-mapping/Screenshots/LightProbe.png) |

## Jade Material

玉石材质组合基础漫反射、厚度透射、环境反射、Fresnel 和附加光源，在实时渲染预算内近似通透感。

<p align="center">
  <img src="Assets/environment-mapping/Screenshots/jade_left.png" width="49%" alt="玉石材质左侧效果">
  <img src="Assets/environment-mapping/Screenshots/jade_right.png" width="49%" alt="玉石材质右侧效果">
</p>

- **基础漫反射与天光**：保留玉石固有色和实体感。
- **厚度背光透射**：根据视线、光线、法线与 Thickness Map 近似薄处透光。
- **环境反射**：采样 Cubemap 表现光滑表面反射。
- **Fresnel**：增强轮廓区域反射并减弱正面反射。
- **ForwardAdd**：为点光源和聚光灯逐灯叠加带衰减的透射光。

| 漫反射 | 厚度透射 | Cubemap 反射 |
| :---: | :---: | :---: |
| ![玉石漫反射](Assets/environment-mapping/Screenshots/jade_diffuse.png) | ![玉石厚度透射](Assets/environment-mapping/Screenshots/jade_tanslight.png) | ![玉石环境反射](Assets/environment-mapping/Screenshots/jade_cubemap.png) |

| Fresnel | ForwardAdd | 最终效果 |
| :---: | :---: | :---: |
| ![玉石 Fresnel](Assets/environment-mapping/Screenshots/jade_fresnel.png) | ![玉石 ForwardAdd](Assets/environment-mapping/Screenshots/jade_fwdadd.png) | ![玉石最终效果](Assets/environment-mapping/Screenshots/jade_right.png) |

> 玉石效果是实时视觉近似，并非物理精确的次表面散射。

## 项目环境

- Unity `6000.3.16f1`
- Built-in Render Pipeline
- Post Processing `3.5.4`
- ShaderLab / HLSL
- Git LFS
