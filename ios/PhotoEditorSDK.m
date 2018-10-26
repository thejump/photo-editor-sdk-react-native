//
//  PhotoEditorSDK.m
//  FantasticPost
//
//  Created by Michel Albers on 16.08.17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "PhotoEditorSDK.h"
#import "React/RCTUtils.h"
#import "AVHexColor.h"

// Config options
NSString* const kBackgroundColorEditorKey = @"backgroundColorEditor";
NSString* const kBackgroundColorMenuEditorKey = @"backgroundColorMenuEditor";
NSString* const kBackgroundColorCameraKey = @"backgroundColorCamera";
NSString* const kCameraRollAllowedKey = @"cameraRowAllowed";
NSString* const kShowFiltersInCameraKey = @"showFiltersInCamera";
NSString* const kForceCrop = @"forceCrop";
NSString* const kEditorCaption = @"editorCaption";
NSInteger*loaded=0;

// Menu items
typedef enum {
    transformTool,
    filterTool,
    focusTool,
    adjustTool,
    textTool,
    stickerTool,
    overlayTool,
    brushTool,
    magic,
    textDesignTool,
} FeatureType;



@interface PhotoEditorSDK ()

@property (strong, nonatomic) RCTPromiseResolveBlock resolver;
@property (strong, nonatomic) RCTPromiseRejectBlock rejecter;
@property (strong, nonatomic) PESDKPhotoEditViewController* editController;
@property (strong, nonatomic) PESDKCameraViewController* cameraController;
@property (strong, nonatomic) PESDKTransformToolControllerOptions* transFormController;
@property (strong, nonatomic) PESDKPhotoEditToolController* toolController;


@end



@implementation PhotoEditorSDK
RCT_EXPORT_MODULE(PESDK);

static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";


+(NSString *) randomStringWithLength: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform([letters length])]];
    }
    
    return randomString;
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (NSDictionary *)constantsToExport
{
    return @{
             @"backgroundColorCameraKey":       kBackgroundColorCameraKey,
             @"backgroundColorEditorKey":       kBackgroundColorEditorKey,
             @"backgroundColorMenuEditorKey":   kBackgroundColorMenuEditorKey,
             @"cameraRollAllowedKey":           kCameraRollAllowedKey,
             @"showFiltersInCameraKey":         kShowFiltersInCameraKey,
             @"forceCrop":                      kForceCrop,
        @"editorCaption":                      kEditorCaption,
             @"transformTool":                  [NSNumber numberWithInt: transformTool],
             @"filterTool":                     [NSNumber numberWithInt: filterTool],
             @"focusTool":                      [NSNumber numberWithInt: focusTool],
             @"adjustTool":                     [NSNumber numberWithInt: adjustTool],
             @"textTool":                       [NSNumber numberWithInt: textTool],
             @"stickerTool":                    [NSNumber numberWithInt: stickerTool],
             @"overlayTool":                    [NSNumber numberWithInt: overlayTool],
             @"brushTool":                      [NSNumber numberWithInt: brushTool],
             @"magic":                          [NSNumber numberWithInt: magic],
             @"textDesignTool": [NSNumber numberWithInt: textDesignTool],
    };
}

-(void)_openEditor: (UIImage *)image config: (PESDKConfiguration *)config features: (NSArray*)features resolve: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)reject {
    self.resolver = resolve;
    self.rejecter = reject;
    
    // Just an empty model
    PESDKPhotoEditModel* photoEditModel = [[PESDKPhotoEditModel alloc] init];
    
    
    // Build the menu items from the features array if present
    NSMutableArray<PESDKPhotoEditMenuItem *>* menuItems = [[NSMutableArray alloc] init];
    
    // Default features
    if (features == nil || [features count] == 0) {
        features = @[
          [NSNumber numberWithInt: transformTool],
          [NSNumber numberWithInt: filterTool],
          [NSNumber numberWithInt: focusTool],
          [NSNumber numberWithInt: adjustTool],
          [NSNumber numberWithInt: textDesignTool],
          [NSNumber numberWithInt: textTool],
          [NSNumber numberWithInt: stickerTool],
          [NSNumber numberWithInt: overlayTool],
          [NSNumber numberWithInt: brushTool],
          [NSNumber numberWithInt: magic]
        ];
    }
    
    [features enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        int feature = [obj intValue];
        switch (feature) {
            case transformTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createTransformToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case filterTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createFilterToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case focusTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createFocusToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case adjustTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createAdjustToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case textTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createTextToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case textDesignTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createTextDesignToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case stickerTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createStickerToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case overlayTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createOverlayToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case brushTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createBrushToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case magic: {
                PESDKActionMenuItem* menuItem = [PESDKActionMenuItem createMagicItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithActionMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
               
            }
            default:
                break;
        }
    }];
    
    
    NSString* overlayURL=@"https://d1hwjrzco5rhv1.cloudfront.net/imageAssets/photoeditor/";
    
    
    NSMutableArray* overlays = [[NSMutableArray alloc] init];

    //NSMutableArray<PESDKOverlay *> *overlays = [[PESDKOverlay alloc] mutableCopy];
    [overlays addObject:PESDKOverlay.none];
    [overlays addObject:[[PESDKOverlay alloc]  initWithIdentifier:@"imgly_overlay_vintage" displayName:@"Vintage"
                                                              url:[[NSBundle pesdkBundle]  URLForResource:@"imgly_overlay_vintage" withExtension:@"jpg"]
                                                     thumbnailURL:[[NSBundle pesdkBundle]  URLForResource:@"imgly_overlay_vintage_thumb" withExtension:@"jpg"]
                                                 initialBlendMode:PESDKBlendModeDarken   ]];
    [overlays addObject:[[PESDKOverlay alloc]  initWithIdentifier:@"Painting" displayName:@"Painting"
                                                              url: [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", overlayURL, @"imgly_overlay_painting.jpg"]]
                                                     thumbnailURL: [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", overlayURL, @"imgly_overlay_painting_thumb.jpg"]]
                                                 initialBlendMode:PESDKBlendModeOverlay   ]];
    [overlays addObject:[[PESDKOverlay alloc]  initWithIdentifier:@"Grainy" displayName:@"Grainy"
                                                              url: [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", overlayURL, @"imgly_overlay_grain.jpg"]]
                                                     thumbnailURL: [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", overlayURL, @"imgly_overlay_grain_thumb.jpg"]]
                                                 initialBlendMode:PESDKBlendModeOverlay   ]];
    [overlays addObject:[[PESDKOverlay alloc]  initWithIdentifier:@"imgly_overlay_rain" displayName:@"Rain"
                                                              url:[[NSBundle pesdkBundle]  URLForResource:@"imgly_overlay_rain" withExtension:@"jpg"]
                                                     thumbnailURL:[[NSBundle pesdkBundle]  URLForResource:@"imgly_overlay_rain_thumb" withExtension:@"jpg"]
                                                 initialBlendMode:PESDKBlendModeOverlay   ]];
    
    [overlays addObject:[[PESDKOverlay alloc]  initWithIdentifier:@"Hearts" displayName:@"Hearts"
                                                              url: [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", overlayURL, @"imgly_overlay_hearts.jpg"]]
                                                     thumbnailURL: [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", overlayURL, @"imgly_overlay_hearts_thumb.jpg"]]
                                                 initialBlendMode:PESDKBlendModeScreen   ]];
     [overlays addObject:[[PESDKOverlay alloc]  initWithIdentifier:@"Wall" displayName:@"Wall"
                                                              url: [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", overlayURL, @"imgly_overlay_wall2.jpg"]]
                                                     thumbnailURL: [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", overlayURL, @"imgly_overlay_wall2_thumb.jpg"]]
                                                 initialBlendMode:PESDKBlendModeOverlay   ]];
    [overlays addObject:[[PESDKOverlay alloc]  initWithIdentifier:@"imgly_overlay_lightleak1" displayName:@"Lightleak"
                                                              url:[[NSBundle pesdkBundle]  URLForResource:@"imgly_overlay_lightleak1" withExtension:@"jpg"]
                                                     thumbnailURL:[[NSBundle pesdkBundle]  URLForResource:@"imgly_overlay_lightleak1_thumbnail" withExtension:@"jpg"]
                                                 initialBlendMode:PESDKBlendModeScreen   ]];
    [overlays addObject:[[PESDKOverlay alloc]  initWithIdentifier:@"imgly_overlay_tj" displayName:@"The Jump"
                                                              url: [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", overlayURL, @"imgly_overlay_tj4.jpg"]]
                                                     thumbnailURL: [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", overlayURL, @"imgly_overlay_tj_thumb.jpg"]]   initialBlendMode:PESDKBlendModeOverlay   ]];

    
    PESDKOverlay.all =overlays;
    
    
    
    
    
 
  
     NSMutableArray<PESDKStickerCategory *> *categories = [[PESDKStickerCategory all] mutableCopy];
    
    if([categories count]<5){
    NSString* url=@"https://d1hwjrzco5rhv1.cloudfront.net/imageAssets/newartwork/";
    
    NSMutableArray* badgeURLs = [[NSMutableArray alloc] init];
    for (int i = 14; i <=16; i++)
    {
        [badgeURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"frame_", @(i),@".png"]]];
    }
    for (int i = 19; i <=29; i++)
    {
        [badgeURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"frame_", @(i),@".png"]]];
    }
    for (int i = 31; i <=31; i++)
    {
        [badgeURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"frame_", @(i),@".png"]]];
    }
   

   
    
    NSMutableArray<PESDKSticker *> *badges = [[NSMutableArray alloc] init];
    for (NSURL *stickerURL in badgeURLs) {
        [badges addObject:[[PESDKSticker alloc] initWithImageURL:stickerURL thumbnailURL:nil identifier:stickerURL.path]];
    }
    [categories addObject:[[PESDKStickerCategory alloc] initWithTitle:@"Badges" imageURL:[NSURL URLWithString: @"https://d1hwjrzco5rhv1.cloudfront.net/imageAssets/newartwork/categories/badges.png"] stickers:badges]];
    
    
    NSMutableArray* borderURLs = [[NSMutableArray alloc] init];
    for (int i = 1; i <=5; i++)
    {
        [borderURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"frame_", @(i),@".png"]]];
    }
    for (int i = 8; i <=10; i++)
    {
        [borderURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"frame_", @(i),@".png"]]];
    }
    for (int i = 17; i <=18; i++)
    {
        [borderURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"frame_", @(i),@".png"]]];
    }
    for (int i = 32; i <=42; i++)
    {
        [borderURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"frame_", @(i),@".png"]]];
    }
    NSMutableArray<PESDKSticker *> *borders = [[NSMutableArray alloc] init];
    for (NSURL *stickerURL in borderURLs) {
        [borders addObject:[[PESDKSticker alloc] initWithImageURL:stickerURL thumbnailURL:nil identifier:stickerURL.path]];
    }
    [categories addObject:[[PESDKStickerCategory alloc] initWithTitle:@"Borders" imageURL:[NSURL URLWithString: @"https://d1hwjrzco5rhv1.cloudfront.net/imageAssets/newartwork/categories/borders.png"] stickers:borders]];
    
    NSMutableArray* swashURLs = [[NSMutableArray alloc] init];
    for (int i = 6; i <=7; i++)
    {
        [swashURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"frame_", @(i),@".png"]]];
    }
    for (int i = 43; i <=70; i++)
    {
        [swashURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"frame_", @(i),@".png"]]];
    }
   
    NSMutableArray<PESDKSticker *> *swashes = [[NSMutableArray alloc] init];
    for (NSURL *stickerURL in swashURLs) {
        [swashes addObject:[[PESDKSticker alloc] initWithImageURL:stickerURL thumbnailURL:nil identifier:stickerURL.path]];
    }
    [categories addObject:[[PESDKStickerCategory alloc] initWithTitle:@"Swashes" imageURL:[NSURL URLWithString: @"https://d1hwjrzco5rhv1.cloudfront.net/imageAssets/newartwork/categories/swashes.png"] stickers:swashes]];
    
    
    NSMutableArray* wordURLs = [[NSMutableArray alloc] init];
    for (int i = 11; i <=13; i++)
    {
        [wordURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"frame_", @(i),@".png"]]];
    }
    for (int i = 1; i <=35; i++)
    {
        [wordURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"text_", @(i),@".png"]]];
    }
    for (int i = 151; i <=185; i++)
    {
        [wordURLs addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"object_", @(i),@".png"]]];
    }
    
    NSMutableArray<PESDKSticker *> *words = [[NSMutableArray alloc] init];
    for (NSURL *stickerURL in wordURLs) {
        [words addObject:[[PESDKSticker alloc] initWithImageURL:stickerURL thumbnailURL:nil identifier:stickerURL.path]];
    }
    [categories addObject:[[PESDKStickerCategory alloc] initWithTitle:@"Words" imageURL:[NSURL URLWithString: @"https://d1hwjrzco5rhv1.cloudfront.net/imageAssets/newartwork/categories/words.png"] stickers:words]];
    
    
    NSMutableArray* objectURls = [[NSMutableArray alloc] init];
    for (int i = 1; i <=150; i++)
    {
        [objectURls addObject:  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", url, @"object_", @(i),@".png"]]];
    }
  
    NSMutableArray<PESDKSticker *> *objects = [[NSMutableArray alloc] init];
    for (NSURL *stickerURL in objectURls) {
        [objects addObject:[[PESDKSticker alloc] initWithImageURL:stickerURL thumbnailURL:nil identifier:stickerURL.path]];
    }
    [categories addObject:[[PESDKStickerCategory alloc] initWithTitle:@"Objects" imageURL:[NSURL URLWithString: @"https://d1hwjrzco5rhv1.cloudfront.net/imageAssets/newartwork/categories/outdoor.png"] stickers:objects]];
    }
    PESDKStickerCategory.all = [categories copy];
    
    
  
    NSMutableArray* fonts = [[NSMutableArray alloc] init];

    
    //put this next one first so it's the default font
       [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Avenir" fontName:@"AvenirNext-Regular" identifier:@"Avenir"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Ace of Spades" fontName:@"AceofSpades-Regular" identifier:@"Ace of Spades"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Aerokids" fontName:@"Aerokids" identifier:@"Aerokids"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Alpha Echo" fontName:@"AlphaEcho" identifier:@"Alpha Echo"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Antonio" fontName:@"Antonio-Bold" identifier:@"Antonio"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"AnuDaw" fontName:@"AnuDawItalic" identifier:@"AnuDaw"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Arbour" fontName:@"ArbourOblique-Regular" identifier:@"Arbour"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Arcon" fontName:@"Arcon-Rounded-Regular" identifier:@"Arcon"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Arizonia" fontName:@"Arizonia-Regular" identifier:@"Arizonia"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Avenir Demi" fontName:@"AvenirNext-DemiBold" identifier:@"Avenir Demi"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Avenir Med" fontName:@"AvenirNext-Medium" identifier:@"Avenir Med"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Avenir Bold" fontName:@"AvenirNext-Bold" identifier:@"Avenir Bold"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Avenir Italic" fontName:@"AvenirNext-Italic" identifier:@"Avenir Italic"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Bebas" fontName:@"Bebas" identifier:@"Bebas"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Belligerent" fontName:@"BelligerentMadness" identifier:@"Belligerent"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Black Jack" fontName:@"BlackJack" identifier:@"Black Jack"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Bough" fontName:@"Bough-Condensed" identifier:@"Bough"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Dancing" fontName:@"DancingScript-Bold" identifier:@"Dancing"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"De Valencia" fontName:@"DeValencia-Regular" identifier:@"De Valencia"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Edo" fontName:@"Edo" identifier:@"Edo"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"England" fontName:@"EnglandHandDB" identifier:@"England"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Euphoria" fontName:@"EuphoriaScript-Regular" identifier:@"Euphoria"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"First Test" fontName:@"firsttest" identifier:@"First Test"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Frente H1" fontName:@"FrenteH1-Regular" identifier:@"Frente H1"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Geared Slab" fontName:@"GearedSlab-Extrabold" identifier:@"Geared Slab"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Governor" fontName:@"Governor" identifier:@"Governor"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Hominis" fontName:@"Hominis" identifier:@"Hominis"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Hustle" fontName:@"HustleScript-Bold" identifier:@"Hustle"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"HVD Rowdy" fontName:@"HVDRowdy" identifier:@"HVD Rowdy"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Impact" fontName:@"ImpactLabel" identifier:@"Impact"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Kaushan" fontName:@"KaushanScript-Regular" identifier:@"Kaushan"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Langdon" fontName:@"Langdon" identifier:@"Langdon"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"League" fontName:@"LeagueScriptThin-Regular" identifier:@"League"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Lecker" fontName:@"LeckerliOne" identifier:@"Lecker"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Matchbook" fontName:@"Matchbook" identifier:@"Matchbook"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Ocean Beach" fontName:@"OceanBeach-MinorVintage" identifier:@"Ocean Beach"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Oleo Script" fontName:@"OleoScript-Bold" identifier:@"Oleo Script"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Oswald" fontName:@"Oswald-Bold" identifier:@"Oswald"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Paete" fontName:@"PaeteRound" identifier:@"Paete"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Pathway" fontName:@"PathwayGothicOne-Regular" identifier:@"Pathway"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Permanent" fontName:@"PermanentMarker" identifier:@"Permanent"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Pincoya" fontName:@"Pincoyablack-Black" identifier:@"Pincoya"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Playball" fontName:@"Playball-Regular" identifier:@"Playball"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Porter" fontName:@"PorterSansBlock" identifier:@"Porter"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Quatro" fontName:@"Quatro" identifier:@"Quatro"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Quicksand" fontName:@"QuicksandDash-Regular" identifier:@"Quicksand"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Raleway" fontName:@"Raleway-Light" identifier:@"Raleway"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Rancho" fontName:@"Rancho" identifier:@"Rancho"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Restless" fontName:@"RestlessYouthScript-Bold" identifier:@"Restless"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Six Caps" fontName:@"SixCaps" identifier:@"Six Caps"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Slukoni" fontName:@"Slukoni-Medium" identifier:@"Slukoni"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Special Elite" fontName:@"SpecialElite-Regular" identifier:@"Special Elite"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Stone" fontName:@"STONEHARBOUR-Regular" identifier:@"Stone"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Sullivan" fontName:@"Sullivan-Bevel" identifier:@"Sullivan"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Trade Winds" fontName:@"TradeWinds" identifier:@"Trade Winds"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Twilight" fontName:@"TwilightScript" identifier:@"Twilight"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Ubuntu" fontName:@"UbuntuTitling-Bold" identifier:@"Ubuntu"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Yellowtail" fontName:@"Yellowtail" identifier:@"Yellowtail"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Yoga" fontName:@"BeginningYoga" identifier:@"Yoga"]];
    [fonts addObject:[[PESDKFont alloc] initWithDisplayName:@"Yorkshire" fontName:@"YorkshireBrushScript-Regular" identifier:@"Yorkshire"]];
  
    PESDKFontImporter.all=fonts;
    
   
        
    
    [PESDK setBundleImageBlock:^UIImage * _Nullable(NSString * _Nonnull imageName) {
        if ([imageName isEqualToString:@"imgly_icon_save"]) {
            return [UIImage imageNamed:@"up24"];
        }
        return nil;
    }];
    
    
    self.editController = [[PESDKPhotoEditViewController alloc] initWithPhoto:image configuration:config menuItems:menuItems photoEditModel:photoEditModel];
    
    self.editController.toolbar.backgroundColor=[UIColor colorWithRed:0.16 green:0.69 blue:0.75 alpha:1.0];
    
    
    self.editController.delegate = self;
    UIViewController *currentViewController = RCTPresentedViewController();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [currentViewController presentViewController:self.editController animated:YES completion:nil];
    });
}




-(PESDKConfiguration*)_buildConfig: (NSDictionary *)options {
    PESDKConfiguration* config = [[PESDKConfiguration alloc] initWithBuilder:^(PESDKConfigurationBuilder * builder) {
      
        [builder configureStickerToolController:^(PESDKStickerToolControllerOptionsBuilder * b) {
            b.stickerPreviewSize =CGSizeMake(80, 80);
        }];
        
        [builder configurePhotoEditorViewController:^(PESDKPhotoEditViewControllerOptionsBuilder * b) {
            if ([options valueForKey:kBackgroundColorEditorKey]) {
                b.backgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorEditorKey]];
            }
            
            if ([options valueForKey:kBackgroundColorMenuEditorKey]) {
                b.menuBackgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorMenuEditorKey]];
            }
            
            if ([options valueForKey:kForceCrop]) {
                b.forceCropMode = [[options valueForKey:kForceCrop] boolValue];

            }
        
        
             if ([options valueForKey:kEditorCaption]) {
                 b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
                      UILabel* label =view;
                     label.text = [options valueForKey:kEditorCaption];
                     
                 };
                
                }
          
            
        }];
        
        [builder configureCameraViewController:^(PESDKCameraViewControllerOptionsBuilder * b) {
            if ([options valueForKey:kBackgroundColorCameraKey]) {
                b.backgroundColor = [AVHexColor colorWithHexString: (NSString*)[options valueForKey:kBackgroundColorCameraKey]];
            }
            
            if ([[options allKeys] containsObject:kCameraRollAllowedKey]) {
                b.showCameraRoll = [[options valueForKey:kCameraRollAllowedKey] boolValue];
            }
            
            if ([[options allKeys] containsObject: kShowFiltersInCameraKey]) {
                b.showFilters = [[options valueForKey:kShowFiltersInCameraKey] boolValue];
            }
            b.showCancelButton=true;
            
            
            // TODO: Video recording not supported currently
            b.allowedRecordingModesAsNSNumbers = @[[NSNumber numberWithInteger:RecordingModePhoto]];//,[NSNumber numberWithInteger:RecordingModeVideo]];
        }];

        if ([options valueForKey:kForceCrop]) {
             [builder configureTransformToolController:^(PESDKTransformToolControllerOptionsBuilder * _Nonnull options) {
            options.allowFreeCrop = NO;
            options.allowedCropRatios = @[
                                          [[PESDKCropAspect alloc] initWithWidth:1080 height:1920 localizedName:@"Crop" rotatable:NO]
                                            ];
        }];
        }
        
    }];
    
    return config;
}

RCT_EXPORT_METHOD(openEditor: (NSString*)path options: (NSArray *)features options: (NSDictionary*) options resolve: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)reject) {
    UIImage* image = [UIImage imageWithContentsOfFile: path];
    PESDKConfiguration* config = [self _buildConfig:options];
    [self _openEditor:image config:config features:features resolve:resolve reject:reject];
}

- (void)close {
    UIViewController *currentViewController = RCTPresentedViewController();
    [currentViewController dismissViewControllerAnimated:YES completion:nil];
}

RCT_EXPORT_METHOD(openCamera: (NSArray*) features options:(NSDictionary*) options resolve: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        
    __weak typeof(self) weakSelf = self;
    UIViewController *currentViewController = RCTPresentedViewController();
    PESDKConfiguration* config = [self _buildConfig:options];
    
    self.cameraController = [[PESDKCameraViewController alloc] initWithConfiguration:config];
   // [self.cameraController.cameraController setupWithInitialRecordingMode:RecordingModePhoto error:nil];
    
  //  UISwipeGestureRecognizer* swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
  //  swipeDownRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    
   // [self.cameraController.view addGestureRecognizer:swipeDownRecognizer];
    [self.cameraController setCompletionBlock:^(UIImage * image, NSURL * _) {
       // if(image){
            [currentViewController dismissViewControllerAnimated:YES completion:^{
          
            [weakSelf _openEditor:image config:config features:features resolve:resolve reject:reject];
           
        }];
    /*    }
        else{
            [weakSelf saveVideo:_.absoluteString resolve:resolve];
        }*/
    }];
        [self.cameraController setCancelBlock:^{
           [weakSelf myCancelCamera:resolve];
        }];
         
    [currentViewController presentViewController:self.cameraController animated:YES completion:nil];
      });
}

-(void)myCancelCamera: (RCTPromiseResolveBlock)resolve{
    resolve(nil);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cameraController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    });
}

-(void)saveVideo:(NSString *)path resolve: (RCTPromiseResolveBlock)resolve{
    resolve(@{@"path":path,@"video":@true});
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cameraController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    });
}

-(void)photoEditViewControllerDidCancel:(PESDKPhotoEditViewController *)photoEditViewController {
    if (self.resolver != nil) {
        //        self.rejecter(@"DID_CANCEL", @"User did cancel the editor", nil);
        self.resolver(nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.editController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
        });
    }
}

-(void)photoEditViewControllerDidFailToGeneratePhoto:(PESDKPhotoEditViewController *)photoEditViewController {
    if (self.rejecter != nil) {
        self.rejecter(@"DID_FAIL_TO_GENERATE_PHOTO", @"Photo generation failed", nil);
        self.rejecter = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.editController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
        });
        
    }
}

-(void)photoEditViewController:(PESDKPhotoEditViewController *)photoEditViewController didSaveImage:(UIImage *)image imageAsData:(NSData *)data {
    if ([data length]<=0) {
        data = UIImageJPEGRepresentation(image, 1.0);
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *randomPath = [PhotoEditorSDK randomStringWithLength:10];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:
                      [randomPath stringByAppendingString:@".jpg"] ];
    
    [data writeToFile:path atomically:YES];
    
    
    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    response[@"path"] = path;
    response[@"width"] = @(image.size.width);
    response[@"height"] = @(image.size.height);
     self.resolver(response);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.editController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    });
}

-(void)photoEditViewController:(PESDKPhotoEditViewController *)photoEditViewController didDismissToolController:(PESDKPhotoEditToolController * _Nonnull)toolController{
  
    self.editController.toolbar.backgroundColor=[UIColor colorWithRed:0.16 green:0.69 blue:0.75 alpha:1.0];
    
}

-(void)photoEditViewController:(PESDKPhotoEditViewController *)photoEditViewController willPresentToolController:(PESDKPhotoEditToolController * _Nonnull)toolController{
    self.editController.toolbar.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
    
}

/*
-(void)photoEditViewController:(PESDKPhotoEditToolController *)photoEditToolController toolController {
    if (self.resolver != nil) {
        //        self.rejecter(@"DID_CANCEL", @"User did cancel the editor", nil);
        self.resolver(nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.editController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
        });
    }
}*/

@end
