import AppKit
let root = URL(fileURLWithPath:CommandLine.arguments[1])
let set = root.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at:set,withIntermediateDirectories:true)
func draw(_ size:Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:size,pixelsHigh:size,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep:bitmap)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x:CGFloat(size)/1024,y:CGFloat(size)/1024)
    let outer = NSBezierPath(roundedRect:NSRect(x:16,y:16,width:992,height:992),xRadius:220,yRadius:220)
    NSGradient(colors:[NSColor(srgbRed:0.05,green:0.08,blue:0.09,alpha:1),NSColor(srgbRed:0.10,green:0.18,blue:0.17,alpha:1)])!.draw(in:outer,angle:60)
    NSColor.white.withAlphaComponent(0.12).setStroke();outer.lineWidth=3;outer.stroke()
    let card = NSBezierPath(roundedRect:NSRect(x:178,y:186,width:668,height:652),xRadius:118,yRadius:118)
    NSColor(srgbRed:0.03,green:0.05,blue:0.055,alpha:1).setFill();card.fill()
    NSColor.white.withAlphaComponent(0.10).setStroke();card.lineWidth=3;card.stroke()
    let mint=NSColor(srgbRed:0.59,green:0.94,blue:0.78,alpha:1)
    mint.withAlphaComponent(0.13).setFill()
    NSBezierPath(roundedRect:NSRect(x:238,y:642,width:264,height:36),xRadius:18,yRadius:18).fill()
    let pulse=NSBezierPath();pulse.move(to:NSPoint(x:246,y:493))
    for p in [(356,493),(411,563),(477,395),(547,602),(613,493),(780,493)] { pulse.line(to:NSPoint(x:p.0,y:p.1)) }
    pulse.lineWidth=32;pulse.lineCapStyle = .round;pulse.lineJoinStyle = .round;mint.setStroke();pulse.stroke()
    mint.setFill();NSBezierPath(ovalIn:NSRect(x:240,y:284,width:46,height:46)).fill()
    mint.withAlphaComponent(0.40).setFill();NSBezierPath(roundedRect:NSRect(x:322,y:293,width:242,height:28),xRadius:14,yRadius:14).fill()
    mint.withAlphaComponent(0.13).setFill();NSBezierPath(roundedRect:NSRect(x:598,y:293,width:148,height:28),xRadius:14,yRadius:14).fill()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using:.png,properties:[:])!
}
for size in [16,32,128,256,512] {
    try draw(size).write(to:set.appendingPathComponent("icon_\(size)x\(size).png"))
    try draw(size*2).write(to:set.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
try draw(1024).write(to:root.appendingPathComponent("icon.png"))
