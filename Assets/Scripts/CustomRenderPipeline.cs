using UnityEngine;
using UnityEngine.Rendering;

public class CustomRenderPipeline : RenderPipeline
{
    /// <summary>
    /// This method is called by Unity during the rendering process.
    /// It receives the rendering context (which contains the data to execute GPU commands) and a list of cameras.
    /// </summary>
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        // Each camera renders independently, so we delegate the logic to RenderSingleCamera.
        foreach (var camera in cameras)
        {
            // handle both scene and game camera
            if(camera.cameraType is CameraType.SceneView or CameraType.Game)
            {
                RenderSingleCamera(context, camera);
            }
        }
    }

    private void RenderSingleCamera(ScriptableRenderContext context, Camera camera)
    {
        // set up the camera
        // Configures the GPU to use the camera’s position, projection, and view settings for rendering.
        // Prepares the rendering pipeline to draw objects as the camera sees them.
        context.SetupCameraProperties(camera);
        
        // culling
        // Determines which objects are visible to the camera (based on frustum culling).
        // Prevents rendering objects outside the camera’s view, improving performance.
        if (!camera.TryGetCullingParameters(out ScriptableCullingParameters cullingParameters))
        {
            return;
        }
        
        // Executes the culling process and returns CullingResults, which contains all visible objects.
        CullingResults cullingResults = context.Cull(ref cullingParameters);
        
        // Create a CommandBuffer directly
        // CommandBuffer is used to send rendering instructions to the GPU.
        CommandBuffer cmd = new CommandBuffer { name = "Render Camera" };
        
        // set up directional light
        if (RenderSettings.sun != null && RenderSettings.sun.enabled)
        {
            Light mainLight = RenderSettings.sun; // main directional light
            cmd.SetGlobalVector("_WorldSpaceLightPos0", -mainLight.transform.forward); // direction of the light
            cmd.SetGlobalColor("_LightColor0", mainLight.color * mainLight.intensity); // color of the light, light color and intensity
        }
        else
        {
            // No directional light: clear light data
            cmd.SetGlobalVector("_WorldSpaceLightPos0", Vector3.zero);  // No light direction
            cmd.SetGlobalColor("_LightColor0", Color.black);                // No light color
        }
        
        // clear the screen with a black color
        cmd.ClearRenderTarget(true, true, Color.black);
        context.ExecuteCommandBuffer(cmd);
        
        // Release the CommandBuffer (to avoid memory leaks)
        cmd.Release();
        
        // Draw objects, Configures how objects should be drawn, specifying the shader pass (ShaderTagId) and sorting order.
        var drawingSettings = new DrawingSettings(new ShaderTagId("UniversalForward"), new SortingSettings(camera));
        
        // Render opaque objects, Filters objects based on their render queue (e.g., opaque objects with queue 0–2500).
        var opaqueFilter = new FilteringSettings(RenderQueueRange.opaque);
        // Draws all visible opaque objects from the cullingResults.
        context.DrawRenderers(cullingResults, ref drawingSettings, ref opaqueFilter);
        
        // Render transparent objects, Same as opaque rendering, but filters objects in the transparent render queue (2501–5000).
        // Ensures transparent objects are drawn after opaque objects for proper blending.
        var transparentFilter = new FilteringSettings(RenderQueueRange.transparent);
        context.DrawRenderers(cullingResults, ref drawingSettings, ref transparentFilter);

        // Sends all queued rendering commands to the GPU. and Finalizes the rendering for the current camera.
        context.Submit();
    }
}
