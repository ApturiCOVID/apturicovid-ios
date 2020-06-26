import CocoaLumberjack

let justPrintError: ((Error) -> Void) = { error in
    DDLogError(error.localizedDescription)
}

let justPrintCompleted: (() -> Void) = {
    DDLogInfo("Completed!")
}
