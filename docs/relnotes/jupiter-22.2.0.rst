Jupiter/Mesa 22.2.0 Release Notes / 2022-04-27
==============================================

This new RADV release contains a few number of new extensions, more RT
features, few compiler optimizations and a bunch of various bug fixes.

New features
------------

- Implemented VK_KHR_ray_query
- Implemented VK_VALVE_descriptor_set_host_mapping (only exposed for vkd3d)
- Implemented VK_EXT_depth_clip_control (mostly for Zink)
- Implemented various RT features
- Preliminary work for graphics pipeline library
- Very preliminary work for video support

Performance fixes
-----------------

- Removed FS color exports in presence of holes
- Optimized clearing VRAM allocations only when necessary
- Inlined more push constants into user SGPRS
- Optimized global/shader memory loads/stores with ACO
- Optimized building acceleration structure with LBVH
- Various other ACO/NIR optimizations
- Various minor CPU optimizations in RADV

Bug fixes
---------

- Fixed a bug with the primitive ID and NGG culling
  (https://gitlab.freedesktop.org/mesa/mesa/-/issues/6050)
- Disabled DCC for various D3D9 games like GTA IV or Fable Anniversary
  (https://gitlab.freedesktop.org/mesa/mesa/-/issues/4424)
- Fixed indirect dispatches on the compute queue
  (fixed a GPU hang with Control and raytracing)
- Fixed missing destruction of the inotify thread
  (fixed a CPU crash with The Witcher 3 and RADV_FORCE_VRS_CONFIG_FILE)
- Enabled radv_disable_aniso_single_level for DXVK/vkd3d
  (to prevent issues because this is the default D3D logic)
- Fixed hashing pipeline layout with ycbcr samplers
  (fixed redundant compilation with Gamescope)
- Fixed an incorrect offset with conditional rendering
  (fixed a bunch of conditional rendering tests with Zink)
- Fixed various dynamic states handling with internal driver operations
  (fixed a bunch of tests with Zink)
- Fixed queries by suspending/resuming them with internal driver operations
  (fixed various tests with Zink)
- Fixed flushing conditional rendering on GFX9+
  (fixed a test with Zink)
- Fixed incorrect emission of a texture instruction with ACO
  (https://gitlab.freedesktop.org/mesa/mesa/-/issues/5838)
- Fixed potential GPU hangs with NGG VS
- Fixed potential pipeline cache keys issues
- Fixed a synchronization issue with transfer operations and CP DMA
  (https://gitlab.freedesktop.org/mesa/mesa/-/issues/5911)
- Fixed 64-bit NGG GS output stores
  (https://gitlab.freedesktop.org/mesa/mesa/-/issues/6301)
- Fixed 64-bit IO with ACO
  (https://gitlab.freedesktop.org/mesa/mesa/-/issues/6276)
- Fixed a rendering issue with RAGE2 and ACO
  (https://gitlab.freedesktop.org/mesa/mesa/-/issues/4329)
- Fixed linking of XFB varyings
  (https://gitlab.freedesktop.org/mesa/mesa/-/issues/6301)
- Added a workaround to fix a game bug with Grid Autosport
  (https://gitlab.freedesktop.org/mesa/mesa/-/issues/4228)
- Various fixes for NV mesh shaders
- Various other fixes for CTS
- Various other fixes found with Zink over RADV
