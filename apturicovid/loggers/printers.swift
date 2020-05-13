import CocoaLumberjack

let justPrintError: ((Error) -> Void) = { error in
    DDLogInfo(error.localizedDescription)
}

let justPrintCompleted: (() -> Void) = {
    DDLogInfo("Completed!")
}
