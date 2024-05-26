//
//  ImageConversion.swift
//  localizr
//
//  Created by Antonella Calvia on 20/05/2024.
//

import Foundation



extension UIImage {
    func getOrCreateGImage() -> CGImage? {
        if let cgImage = self.cgImage {
            return cgImage
        }
        
        if let ci = self.ciImage {
            let context = CIContext()
            guard let cgImage = context.createCGImage(ci, from: ci.extent) else { return nil }
            return cgImage
        }
        
        return nil
    }
    
    func asFloatArray(max_size: Int) -> ([Float32], Int, Int)? {
        guard let cgImage = self.getOrCreateGImage()
        else { return nil}
        
        let w = cgImage.width
        let h = cgImage.height
        
        let max_dim = max(w,h)
        
        var nw = w
        var nh = h
        if max_dim > max_size {
            let scale = Double(max_size) / Double(max(w,h))
            nw = Int(Double(w) * scale)
            nh = Int(Double(h) * scale)
        }
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * nw
        let bitsPerComponent = 8
        var rawBytes: [UInt8] = [UInt8](repeating:0, count: nw * nh * 4)
        rawBytes.withUnsafeMutableBytes { ptr in
           let context = CGContext(data: ptr.baseAddress,
                                   width: nw,
                                   height: nh,
                                   bitsPerComponent: bitsPerComponent,
                                   bytesPerRow : bytesPerRow,
                                   space: CGColorSpaceCreateDeviceRGB(),
                                   bitmapInfo:  CGImageAlphaInfo.premultipliedLast.rawValue)
            let rect = CGRect(x: 0, y: 0, width: nw, height: nh)
            context?.draw(cgImage, in: rect)
        }
        var buffer: [Float32] = [Float32](repeating: 0, count: nw * nh * 3)
        for i in 0 ..< nw * nh {
            buffer[3*i + 0] = Float32(rawBytes[i * 4 + 0])
            buffer[3*i + 1] = Float32(rawBytes[i * 4 + 1])
            buffer[3*i + 2] = Float32(rawBytes[i * 4 + 2])
        }
        return (buffer, nw, nh)
    }
}
