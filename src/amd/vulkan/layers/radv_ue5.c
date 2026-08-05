/*
 * Copyright © 2026 Valve Corporation
 *
 * SPDX-License-Identifier: MIT
 */

#include "radv_cmd_buffer.h"
#include "radv_device.h"
#include "radv_entrypoints.h"

VKAPI_ATTR void VKAPI_CALL
ue5_CmdSetViewport(VkCommandBuffer commandBuffer, uint32_t firstViewport, uint32_t viewportCount,
                   const VkViewport *pViewports)
{
   VK_FROM_HANDLE(radv_cmd_buffer, cmd_buffer, commandBuffer);
   const struct radv_device *device = radv_cmd_buffer_device(cmd_buffer);
   struct radv_cmd_state *state = &cmd_buffer->state;
   const uint32_t total_count = firstViewport + viewportCount;

   /* UE5 has a bug with multi viewport because it tries to set 2 viewports dynamically while the
    * viewport count is static and set to 1 from the PSO. This basically causes any native Vulkan
    * applications that use instanced stereo to only render the left eye. The workaround is to
    * force-update the count here.
    */
   if (state->dynamic.vk.vp.viewport_count < total_count)
      state->dynamic.vk.vp.viewport_count = total_count;

   device->layer_dispatch.app.CmdSetViewport(commandBuffer, firstViewport, viewportCount, pViewports);
}

VKAPI_ATTR void VKAPI_CALL
ue5_CmdSetScissor(VkCommandBuffer commandBuffer, uint32_t firstScissor, uint32_t scissorCount,
                  const VkRect2D *pScissors)
{
   VK_FROM_HANDLE(radv_cmd_buffer, cmd_buffer, commandBuffer);
   const struct radv_device *device = radv_cmd_buffer_device(cmd_buffer);
   struct radv_cmd_state *state = &cmd_buffer->state;
   const uint32_t total_count = firstScissor + scissorCount;

   /* Same issue with scissor. */
   if (state->dynamic.vk.vp.scissor_count < total_count)
      state->dynamic.vk.vp.scissor_count = total_count;

   device->layer_dispatch.app.CmdSetScissor(commandBuffer, firstScissor, scissorCount, pScissors);
}
