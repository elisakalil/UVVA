import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Makes DefaultAvatar (DesignSystem Media.xcassets), the picture of a profile with no photo: a still crop of the page
// photo (Background) with the figure (Avatar) over it, so the app never loads the whole page photo for an avatar.
// Run again when the page photo or the figure changes, from Application/Packages/DesignSystem/Sources/DesignSystem/
// Resources/Media.xcassets:
//   swift ../../../../../../Scripts/make_default_avatar.swift Background.imageset/bg1-sm.png \
//     Avatar.imageset/avatar.png DefaultAvatar.imageset/default-avatar.jpg
//
// The crop is the one the avatar used to draw live:
// the page photo filling a square, scaled 1.8× around (0.3, 0.22), and the figure at 72 % of the side, 14 % low.
let args = CommandLine.arguments
let (backgroundPath, figurePath, outputPath) = (args[1], args[2], args[3])
let side = 480

func load(_ path: String) -> CGImage {
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}

let background = load(backgroundPath)
let figure = load(figurePath)
let (w, h) = (Double(background.width), Double(background.height))
// scaledToFill in a unit square: the photo is 1 wide, h/w tall, centred.
let top = (1 - h / w) / 2
let (scale, ax, ay) = (1.8, 0.3, 0.22)
// The part of the unscaled square that shows once scaled about the anchor.
let x0 = ax - ax / scale, y0 = ay - ay / scale, size = 1 / scale
let crop = CGRect(x: x0 * w, y: (y0 - top) * w, width: size * w, height: size * w).integral
let cropped = background.cropping(to: crop)!

let context = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.interpolationQuality = .high
// Behind the photo, `Avatar`'s own ground, in case the crop leaves an edge.
context.setFillColor(red: 0x5E / 255, green: 0x7A / 255, blue: 0x80 / 255, alpha: 1)
context.fill(CGRect(x: 0, y: 0, width: side, height: side))
context.draw(cropped, in: CGRect(x: 0, y: 0, width: side, height: side))
// The figure: 72 % of the side, centred, 14 % below centre (Core Graphics counts y from the bottom).
let figureSide = 0.72 * Double(side)
let figureX = (Double(side) - figureSide) / 2
let figureYFromTop = figureX + 0.14 * Double(side)
context.draw(figure, in: CGRect(x: figureX, y: Double(side) - figureYFromTop - figureSide, width: figureSide, height: figureSide))

let image = context.makeImage()!
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: outputPath) as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.86] as CFDictionary)
CGImageDestinationFinalize(destination)
print("crop", crop, "->", outputPath)
