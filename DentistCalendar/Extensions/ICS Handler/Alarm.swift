import Foundation

public struct Alarm {
    public var subComponents: [CalendarComponent] = []
    public var otherAttrs = [String:String]()
}

extension Alarm: IcsElement {
    public mutating func addAttribute(attr: String, _ value: String) {
        switch attr {
            default:
                otherAttrs[attr] = value
        }
    }
}

extension Alarm: CalendarComponent {
    public func toCal() -> String {
        var str = "BEGIN:VALARM\n"

        for (key, val) in otherAttrs {
            str += "\(key):\(val)\n"
        }

        str += "END:VALARM"
        return str
    }
}
