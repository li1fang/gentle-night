import AppKit
import MetalKit

struct MaskUniforms {
    var progress: Float
    var mode: UInt32
    var seed: UInt32
    var bias: Float = 3
}

@MainActor final class Renderer {
    let device: MTLDevice
    let queue: MTLCommandQueue
    let pipeline: MTLRenderPipelineState
    init() throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
            throw NSError(domain: "GentleNight", code: 1, userInfo: [NSLocalizedDescriptionKey: "Metal unavailable"])
        }
        self.device = device; self.queue = queue
        let library = try device.makeLibrary(source: Self.shader, options: nil)
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexMain")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentMain")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
    }
    func encode(texture: MTLTexture, uniforms: MaskUniforms, command: MTLCommandBuffer) {
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { return }
        var values = uniforms
        var size = SIMD2<Float>(Float(texture.width), Float(texture.height))
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&values, length: MemoryLayout<MaskUniforms>.stride, index: 0)
        encoder.setFragmentBytes(&size, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
    }
    @discardableResult func draw(view: MTKView, uniforms: MaskUniforms) -> Bool {
        guard let drawable = view.currentDrawable, let command = queue.makeCommandBuffer() else { return false }
        encode(texture: drawable.texture, uniforms: uniforms, command: command)
        command.present(drawable); command.commit()
        return true
    }
    /// Executes the real GPU shader offscreen; no desktop capture or display changes.
    func selfTest() throws {
        let width = 96, height = 54
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        descriptor.storageMode = .shared; descriptor.usage = [.renderTarget]
        guard let texture = device.makeTexture(descriptor: descriptor) else { throw failure("No texture") }
        for mode: UInt32 in 0...2 {
            var previous = [UInt8](repeating: 0, count: width * height)
            var snapshots = [[UInt8]]()
            for step in 0...20 {
                let pixels = try renderBytes(texture, uniforms: .init(progress: Float(step) / 20, mode: mode, seed: 42))
                var alphas = [UInt8]()
                for i in 0..<(width * height) {
                    guard pixels[i*4] == 0 && pixels[i*4+1] == 0 && pixels[i*4+2] == 0 else { throw failure("Nonblack RGB") }
                    let a = pixels[i*4+3]
                    guard a >= previous[i] else { throw failure("Relit pixel") }
                    if step == 0 && a != 0 { throw failure("Unclear start") }
                    if step == 20 && a != 255 { throw failure("Incomplete black") }
                    if mode == 2 && a != 0 && a != 255 { throw failure("Nonbinary alpha") }
                    alphas.append(a)
                }
                previous = alphas; snapshots.append(pixels)
            }
            for step in (0...20).reversed() {
                let bytes = try renderBytes(texture, uniforms: .init(progress: Float(step) / 20, mode: mode, seed: 42))
                guard bytes == snapshots[step] else { throw failure("Reverse path differs") }
            }
        }
        print("GPU PASS: 3 modes; 126 renders; exact endpoints, black RGB, monotonicity, binary probability mask, deterministic reverse.")
    }
    private func renderBytes(_ texture: MTLTexture, uniforms: MaskUniforms) throws -> [UInt8] {
        guard let command = queue.makeCommandBuffer() else { throw failure("No command buffer") }
        encode(texture: texture, uniforms: uniforms, command: command)
        command.commit(); command.waitUntilCompleted()
        guard command.status == .completed else { throw failure(command.error?.localizedDescription ?? "GPU failed") }
        var bytes = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
        bytes.withUnsafeMutableBytes { buffer in
            texture.getBytes(buffer.baseAddress!, bytesPerRow: texture.width * 4, from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
        }
        return bytes
    }
    private func failure(_ text: String) -> NSError {
        NSError(domain: "GentleNight.GPU", code: 2, userInfo: [NSLocalizedDescriptionKey: text])
    }
    static let shader = """
    #include <metal_stdlib>
    using namespace metal;
    struct Params { float u; uint mode; uint seed; float bias; };
    vertex float4 vertexMain(uint id [[vertex_id]]) {
        float2 p[3] = {float2(-1,-1), float2(3,-1), float2(-1,3)};
        return float4(p[id],0,1);
    }
    uint hash(uint x) { x ^= x >> 16; x *= 0x7feb352du; x ^= x >> 15; x *= 0x846ca68bu; return x ^ (x >> 16); }
    fragment float4 fragmentMain(float4 p [[position]], constant Params& v [[buffer(0)]], constant float2& size [[buffer(1)]]) {
        float u = clamp(v.u,0.0f,1.0f), a;
        if(u <= 0) a = 0;
        else if(u >= 1) a = 1;
        else if(v.mode == 0) a = u;
        else {
            float2 d = p.xy - size*0.5f;
            float r2 = dot(d,d)/dot(size*0.5f,size*0.5f);
            if(v.mode == 1) {
                float radius = 1-u, inner = max(0.0f,radius-0.08f);
                a = smoothstep(inner,radius,sqrt(r2));
            } else {
                uint key = uint(p.x)*0x9e3779b9u ^ uint(p.y)*0x85ebca6bu ^ v.seed;
                float q = (float(hash(key) >> 9) + 0.5f)/8388608.0f;
                float probability = (1-u)*exp(-v.bias*r2*u/(1-u));
                a = q < probability ? 0 : 1;
            }
        }
        return float4(0,0,0,a);
    }
    """
}
