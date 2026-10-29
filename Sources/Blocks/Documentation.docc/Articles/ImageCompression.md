# Compress images

Make images smaller before you upload them. Select the compression from the network condition.

## Overview

The Imaging module uses Core Graphics, ImageIO and Vision. It is not available on Linux.

All the operations use ``ImageSource`` as input and output. An image source always keeps its
pixels in the `.up` orientation. When you make an image source from JPEG data or from a `UIImage`,
the initializer applies the orientation. Thus the output does not turn a photo by mistake.

### Compress an image to a target size

Use ``ImageCompressor/compress(_:configuration:)``. The function first makes the image smaller to
fit in the maximum dimensions. Then it does a binary search on the JPEG quality to find data that
is not larger than the target size.

```swift
import Blocks

let source = try ImageSource(data: photoData)
let configuration = ImageCompressor.Configuration(targetByteSize: 500_000, maxWidth: 2048)
let result = try ImageCompressor.compress(source, configuration: configuration)
upload(result.data)
```

If the data at the minimum quality is larger than the target, the function returns this data.
Compare ``ImageCompressor/Result/byteSize`` with the target to find this case.

The compression is synchronous and can take some time with large images. Do not call it from the
main actor.

### Select a preset from the network condition

``CompressionPreset`` gives three configurations: ``CompressionPreset/highQuality``,
``CompressionPreset/balanced`` and ``CompressionPreset/compact``.

``NetworkConditionMonitor`` monitors the network. Use its current condition to select a preset:

```swift
let monitor = NetworkConditionMonitor()
monitor.start()

let preset = CompressionPreset.preset(for: monitor.currentCondition)
let result = try ImageCompressor.compress(source, configuration: preset.configuration)
```

To get the changes, iterate on ``NetworkConditionMonitor/conditions``. Each stream first gives the
current condition. When you call ``NetworkConditionMonitor/stop()``, all the streams finish.

### Crop a document

``DocumentDetector`` finds a document in a photo with Vision. It crops the document and, by
default, corrects its perspective:

```swift
if let detection = try await DocumentDetector.detectDocument(in: source) {
    let result = try ImageCompressor.compress(detection.image, configuration: configuration)
}
```

The function returns `nil` if the confidence of the detection is less than
``DocumentDetector/Options/minimumConfidence``.

## Topics

### Images

- ``ImageSource``
- ``ImageResizer``
- ``ImagingError``

### Compression

- ``ImageCompressor``
- ``CompressionPreset``

### Network

- ``NetworkConditionMonitor``
- ``NetworkCondition``

### Documents

- ``DocumentDetector``
