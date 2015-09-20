import CoreImage
import AppKit
import AVFoundation
import ImageIO

func imageDimensionsFitInRatio(ratio: CGFloat, width: CGFloat, height: CGFloat) -> Bool {
    let imageRatio = height / width
    return imageRatio <= 1 && imageRatio >= ratio
}

func findCenterOfFeatures(features: [CIFeature], height: CGFloat) -> CGFloat {
    var center: CGFloat = height / 2
    if features.count > 0 {
        center = 0
        for feature in features where feature.type == "Face" {
            center += CGRectGetMidY(feature.bounds)
        }
        center = center / CGFloat(features.count)
    }
    return center
}

func cropRectangleOnCenter(center: CGFloat, width: CGFloat, height: CGFloat, ratio: CGFloat) -> CGRect {
    let cropHeight = floor(ratio * width)
    let halfCropHeight = cropHeight / 2
    
    var yPosition = center - halfCropHeight
    if center - halfCropHeight < 0 {
        yPosition = 0
    } else if center + halfCropHeight > height {
        yPosition = height - cropHeight
    }
    
    print("center: \(center)")
    print("halfCropHeight: \(halfCropHeight)")
    print("yPosition: \(yPosition)")
    
    return CGRect(x: 0, y: yPosition, width: width, height: cropHeight)
}

print(NSDate())

let paths = [
    "/Users/ben/Desktop/IMG_7743.jpg",
    "/Users/ben/Desktop/IMG_8126.jpg",
    "/Users/ben/Desktop/IMG_8212.jpg",
    "/Users/ben/Desktop/IMG_8797.jpg",
]

let outputDirectory = NSURL(fileURLWithPath: "/Users/ben/Desktop/output/", isDirectory: true)
let ratio:CGFloat = 9/16

for path in paths {
    
    
    let url = NSURL(fileURLWithPath: path)
    if let imageSource = CGImageSourceCreateWithURL(url, nil), dict = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) {
        let properties = dict as NSDictionary
        let widthProperty = kCGImagePropertyPixelWidth as String
        let heightProperty = kCGImagePropertyPixelHeight as String
        if let originalWidth = properties[widthProperty] as? CGFloat, originalHeight = properties[heightProperty] as? CGFloat where imageDimensionsFitInRatio(ratio, width: originalWidth, height: originalHeight)  {
            let options: [NSObject:AnyObject] = [
                kCGImageSourceShouldAllowFloat : true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: Int(542)
            ]
            
            if let initialImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) {
                let width = CGImageGetWidth(initialImage)
                let height = CGImageGetHeight(initialImage)
                let image = CIImage(CGImage: initialImage)
                let options: [String: AnyObject] = [CIDetectorAccuracy:CIDetectorAccuracyLow]
                let detector = CIDetector(ofType:CIDetectorTypeFace, context:nil, options: options)
                let features = detector.featuresInImage(image)
                let center = findCenterOfFeatures(features, height: CGFloat(height))
                
                let crop = cropRectangleOnCenter(center, width: CGFloat(width), height: CGFloat(height), ratio: ratio)
                let croppedImage = image.imageByCroppingToRect(crop)
                
                let representation = NSBitmapImageRep(CIImage: croppedImage)
                
                let fileProperties = [NSImageCompressionFactor: 0.6]
                if let data = representation.representationUsingType(NSBitmapImageFileType.NSJPEGFileType, properties: fileProperties), filename = url.lastPathComponent {
                    let outputURL = outputDirectory.URLByAppendingPathComponent(filename)
                    data.writeToURL(outputURL, atomically: true)
                }
                
            }
        }
    }
}



print(NSDate())

