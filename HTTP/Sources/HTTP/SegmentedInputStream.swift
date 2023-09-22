import Foundation

class SegmentedInputStream : InputStream {
  private let segments: [InputStream]
  private var currentSegment = 0
  private var _streamError: Error?
  private var _streamStatus: Status

  init(segments: [InputStream]) {
    self.segments = segments
    _streamStatus = .notOpen
    super.init(data: Data())
  }

  override var streamError: Error? {
    get { _streamError }
  }

  override var streamStatus: Status {
    get { _streamStatus }
  }

  override func open() {
    _streamStatus = .open
  }

  override func close() {
    _streamStatus = .closed
  }

  override var delegate: StreamDelegate? {
    get {
      nil
    }
    set {
    }
  }

  override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
  }

  override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
  }

  override func property(forKey key: PropertyKey) -> Any? {
    nil
  }

  override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
    if !hasBytesAvailable {
      return 0
    }

    var bytesRead = 0

    while bytesRead < len {
      let segment = segments[currentSegment]

      if segment.streamStatus == .notOpen {
        segment.open()
      }

      let readCount = segment.read(buffer + bytesRead, maxLength: len - bytesRead)
      if readCount == -1 {
        _streamError = segment.streamError
        _streamStatus = .error
        return -1
      }
      if readCount == 0 {
        currentSegment += 1
        if (currentSegment == segments.count) {
          _streamStatus = .atEnd
          return bytesRead
        }
      }

      bytesRead += readCount
    }
    return bytesRead
  }

  override var hasBytesAvailable: Bool {
    currentSegment < segments.count && (segments[currentSegment].streamStatus == .notOpen ||
        segments[currentSegment].hasBytesAvailable)
  }
}
