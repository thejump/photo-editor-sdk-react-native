class AnalyticsClient: PhotoEditorSDK.AnalyticsClient {
  public func logScreenView(_ screenView: PESDKAnalyticsScreenViewName) {
    func parameters(forScreenName screenName: String) -> [NSObject: AnyObject] {
      return GAIDictionaryBuilder.createScreenView().set(screenName, forKey: kGAIScreenName).build() as [NSObject: AnyObject]
    }

    let tracker = GAI.sharedInstance().defaultTracker

    switch screenView {
    case PESDKAnalyticsScreenViewName.camera:
      tracker?.send(parameters(forScreenName: "camera"))
    case PESDKAnalyticsScreenViewName.editor:
      tracker?.send(parameters(forScreenName: "editor"))
    case PESDKAnalyticsScreenViewName.transform:
      tracker?.send(parameters(forScreenName: "transform"))
    case PESDKAnalyticsScreenViewName.filter:
      tracker?.send(parameters(forScreenName: "filter"))
    case PESDKAnalyticsScreenViewName.adjust:
      tracker?.send(parameters(forScreenName: "adjust"))
    case PESDKAnalyticsScreenViewName.textAdd:
      tracker?.send(parameters(forScreenName: "text add"))
    case PESDKAnalyticsScreenViewName.text:
      tracker?.send(parameters(forScreenName: "text"))
    case PESDKAnalyticsScreenViewName.textFont:
      tracker?.send(parameters(forScreenName: "text font"))
    case PESDKAnalyticsScreenViewName.textFontColor:
      tracker?.send(parameters(forScreenName: "text font color"))
    case PESDKAnalyticsScreenViewName.textBackgroundColor:
      tracker?.send(parameters(forScreenName: "text background color"))
    case PESDKAnalyticsScreenViewName.stickerAdd:
      tracker?.send(parameters(forScreenName: "sticker add"))
    case PESDKAnalyticsScreenViewName.sticker:
      tracker?.send(parameters(forScreenName: "sticker"))
    case PESDKAnalyticsScreenViewName.stickerColor:
      tracker?.send(parameters(forScreenName: "sticker color"))
    case PESDKAnalyticsScreenViewName.frame:
      tracker?.send(parameters(forScreenName: "frame"))
    case PESDKAnalyticsScreenViewName.brush:
      tracker?.send(parameters(forScreenName: "brush"))
    case PESDKAnalyticsScreenViewName.brushColor:
      tracker?.send(parameters(forScreenName: "brush color"))
    case PESDKAnalyticsScreenViewName.focus:
      tracker?.send(parameters(forScreenName: "focus"))
    case PESDKAnalyticsScreenViewName.overlay:
      tracker?.send(parameters(forScreenName: "overlay"))
    default:
      break
    }
  }

  public func logEvent(_ event: PESDKAnalyticsEventName, attributes: [PESDKAnalyticsEventAttributeName : Any]?) {
  }
}
