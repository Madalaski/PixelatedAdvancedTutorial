using System.Collections.Generic;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Scripting.APIUpdating;

namespace UnityEngine.Experimental.Rendering.Universal
{
    public class BasicFeature : ScriptableRendererFeature {

        [System.Serializable]
        public class BasicFeatureSettings {

            public LayerMask layerMask = 0;

            public RenderPassEvent Event = RenderPassEvent.BeforeRenderingTransparents;
            
            public Material blitMat = null;

            [Range(1f, 15f)]
            public float pixelDensity = 1f;
        }

        public BasicFeatureSettings settings = new BasicFeatureSettings();

        BasicFeaturePass pass;

        public override void Create() {
            pass = new BasicFeaturePass(settings.Event, settings.blitMat, settings.pixelDensity, settings.layerMask);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(pass);
        }

    }
}
