// [PERF-FIX] Runtime tier-to-asset manifest for automatic GLB variant selection.
export function getAssetPaths(tier) {
  const envOptimized = '/assets/kavya-env.meshopt.glb'
  const envFallback = '/assets/kavya-env.glb'

  if (tier === 'low') {
    return {
      truck: '/assets/tr-final-1k.opt.glb',
      env: envOptimized,
      truckLod1: '/assets/tr-final-lod1.glb',
      truckLod2: '/assets/tr-final-lod2.glb',
      fallbackTruck: '/assets/tr-final.glb',
      fallbackEnv: envFallback,
    }
  }

  return {
    truck: '/assets/tr-final-2k.opt.glb',
    env: envOptimized,
    truckLod1: '/assets/tr-final-lod1.glb',
    truckLod2: '/assets/tr-final-lod2.glb',
    fallbackTruck: '/assets/tr-final.glb',
    fallbackEnv: envFallback,
  }
}
