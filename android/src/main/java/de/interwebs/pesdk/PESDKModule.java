
/**
 * PhotoEditorSDK ReactNative Module
 *
 * Created 08/2017 by Interwebs UG (haftungsbeschränkt)
 * @author Michel Albers <m.albers@interwebs-ug.de>
 * @license The Unlincese (unlincese.org)
 *
 */

package de.interwebs.pesdk;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Dynamic;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableType;

import ly.img.android.pesdk.assets.filter.basic.FilterPackBasic;
import ly.img.android.pesdk.assets.font.basic.FontPackBasic;
import ly.img.android.pesdk.assets.frame.basic.FramePackBasic;
import ly.img.android.pesdk.assets.overlay.basic.OverlayPackBasic;
import ly.img.android.pesdk.assets.sticker.emoticons.StickerPackEmoticons;
import ly.img.android.pesdk.assets.sticker.shapes.StickerPackShapes;
import ly.img.android.pesdk.backend.model.constant.Directory;
import ly.img.android.pesdk.backend.model.state.CameraSettings;
import ly.img.android.pesdk.backend.model.state.EditorLoadSettings;
import ly.img.android.pesdk.backend.model.state.EditorSaveSettings;
import ly.img.android.pesdk.backend.model.state.manager.SettingsList;
import ly.img.android.pesdk.ui.activity.CameraPreviewBuilder;
import ly.img.android.pesdk.ui.activity.ImgLyIntent;
import ly.img.android.pesdk.ui.activity.PhotoEditorBuilder;
import ly.img.android.pesdk.ui.model.state.*;
import ly.img.android.pesdk.ui.utils.PermissionRequest;
import ly.img.android.serializer._3._0._0.PESDKFileWriter;
import ly.img.android.pesdk.ui.panels.item.ToolItem;
import ly.img.android.pesdk.backend.decoder.ImageSource;
import ly.img.android.pesdk.backend.model.state.AssetConfig;
import ly.img.android.pesdk.backend.model.config.CropAspectAsset;
import ly.img.android.pesdk.ui.panels.item.CropAspectItem;
import ly.img.android.pesdk.backend.model.config.FontAsset;
import ly.img.android.pesdk.linker.ConfigMap;
import ly.img.android.pesdk.ui.utils.DataSourceIdItemList;
import ly.img.android.pesdk.ui.panels.item.FontItem;
import ly.img.android.pesdk.backend.model.config.ImageStickerAsset;
import ly.img.android.pesdk.ui.panels.item.StickerCategoryItem;
import ly.img.android.pesdk.ui.panels.item.ImageStickerItem;
import ly.img.android.pesdk.backend.model.config.OverlayAsset;
import ly.img.android.pesdk.backend.model.constant.BlendMode;
import android.net.Uri;
import android.graphics.BitmapFactory;
import com.facebook.react.bridge.*;


import ly.img.android.pesdk.ui.panels.item.OverlayItem;
import android.provider.MediaStore;

import java.io.File;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import android.provider.MediaStore.MediaColumns;
import android.database.Cursor;

public class PESDKModule extends ReactContextBaseJavaModule {

    // the answer to life the universe and everything
    static final int RESULT_CODE_PESDK = 42;

    // Promise for later use
    private Promise mPESDKPromise;

    // Error constants
    private static final String E_ACTIVITY_DOES_NOT_EXIST = "ACTIVITY_DOES_NOT_EXIST";
    private static final String E_PESDK_CANCELED = "USER_CANCELED_EDITING";

    // Features
    public static final String transformTool = "transformTool";
    public static final String filterTool = "filterTool";
    public static final String focusTool = "focusTool";
    public static final String adjustTool = "adjustTool";
    public static final String textTool = "textTool";
    public static final String stickerTool = "stickerTool";
    public static final String overlayTool = "overlayTool";
    public static final String brushTool = "brushTool";
    public static final String magic = "magic";

    // Config options
    public static final String backgroundColorCameraKey = "backgroundColor";
    public static final String backgroundColorEditorKey = "backgroundColorEditor";
    public static final String backgroundColorMenuEditorKey = "backgroundColorMenuEditor";
    public static final String cameraRollAllowedKey = "cameraRollAllowed";
    public static final String showFiltersInCameraKey = "showFiltersInCamera";

    // Listen for onActivityResult
    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            switch (requestCode) {
                case RESULT_CODE_PESDK: {
                    switch (resultCode) {
                        case Activity.RESULT_CANCELED:
                            mPESDKPromise.reject(E_PESDK_CANCELED, "Editor was cancelled");
                            break;
                        case Activity.RESULT_OK:
                            String resultPath = data.getStringExtra(ImgLyIntent.RESULT_IMAGE_PATH);

                            BitmapFactory.Options o = new BitmapFactory.Options();
                            o.inJustDecodeBounds = true;
                            BitmapFactory.decodeFile(resultPath, o);
                            int imageHeight = o.outHeight;
                            int imageWidth = o.outWidth;
                            WritableMap result = Arguments.createMap();
                            result.putString("path",resultPath);

                            result.putInt("width", imageWidth);
                            result.putInt("height", imageHeight);

                            mPESDKPromise.resolve(result);
                            break;
                    }
                    mPESDKPromise = null;
                    break;
                }
            }
        }
    };


    public PESDKModule(ReactApplicationContext context) {
        super(context);
        context.addActivityEventListener(mActivityEventListener);
    }

    // Config builder
    private SettingsList buildConfig(ReadableMap options, @Nullable ReadableArray features, @Nullable String imagePath) {
        SettingsList settingsList = new SettingsList();

        settingsList.getSettingsModel(CameraSettings.class)
                .setExportDir(Directory.DCIM, "PESDK")
                .setExportPrefix("camera_");

        // Set custom editor image export settings
        settingsList.getSettingsModel(EditorSaveSettings.class)
                .setExportDir(Directory.DCIM, "PESDK")
                .setExportPrefix("result_")
                .setSavePolicy(EditorSaveSettings.SavePolicy.RETURN_ALWAYS_ONLY_OUTPUT);


        if(imagePath!=null){
            settingsList.getSettingsModel(EditorLoadSettings.class).setImageSource(Uri.fromFile(new File(imagePath)));
        }

                // TODO: Config options in PESDK v5 are limited compared to iOS (or I didn't find them)

        settingsList.getSettingsModel(UiConfigFilter.class).setFilterList(
                FilterPackBasic.getFilterPack()
        );
        settingsList.getSettingsModel(UiConfigFrame.class).setFrameList(
                FramePackBasic.getFramePack()
        );


UiConfigMainMenu uiConfigMainMenu = settingsList.getSettingsModel(UiConfigMainMenu.class);
// Set the tools you want keep sure you licence is cover the feature and do not forget to include the correct modules in your build.gradle
        //I want text design first if they are creating a jump cover
        if(options.hasKey("androidTextFirst") && options.getBoolean("androidTextFirst")) {
            uiConfigMainMenu.setToolList(
                    new ToolItem("imgly_tool_text_design", R.string.pesdk_textDesign_title_name, ImageSource.create(R.drawable.imgly_icon_tool_text_design)),
                    new ToolItem("imgly_tool_filter", R.string.pesdk_filter_title_name, ImageSource.create(R.drawable.imgly_icon_tool_filters)),
                    new ToolItem("imgly_tool_transform", R.string.pesdk_transform_title_name, ImageSource.create(R.drawable.imgly_icon_tool_transform)),
                    new ToolItem("imgly_tool_adjustment", R.string.pesdk_adjustments_title_name, ImageSource.create(R.drawable.imgly_icon_tool_adjust)),
                    new ToolItem("imgly_tool_sticker_selection", R.string.pesdk_sticker_title_name, ImageSource.create(R.drawable.imgly_icon_tool_sticker)),
                    new ToolItem("imgly_tool_text", R.string.pesdk_text_title_name, ImageSource.create(R.drawable.imgly_icon_tool_text)),
                    new ToolItem("imgly_tool_overlay", R.string.pesdk_overlay_title_name, ImageSource.create(R.drawable.imgly_icon_tool_overlay)),
                    new ToolItem("imgly_tool_frame", R.string.pesdk_frame_title_name, ImageSource.create(R.drawable.imgly_icon_tool_frame)),
                    new ToolItem("imgly_tool_brush", R.string.pesdk_brush_title_name, ImageSource.create(R.drawable.imgly_icon_tool_brush)),
                    new ToolItem("imgly_tool_focus", R.string.pesdk_focus_title_name, ImageSource.create(R.drawable.imgly_icon_tool_focus))
            );
        }
else{
            uiConfigMainMenu.setToolList(
                    new ToolItem("imgly_tool_filter", R.string.pesdk_filter_title_name, ImageSource.create(R.drawable.imgly_icon_tool_filters)),
                    new ToolItem("imgly_tool_text_design", R.string.pesdk_textDesign_title_name, ImageSource.create(R.drawable.imgly_icon_tool_text_design)),
                    new ToolItem("imgly_tool_transform", R.string.pesdk_transform_title_name, ImageSource.create(R.drawable.imgly_icon_tool_transform)),
                    new ToolItem("imgly_tool_adjustment", R.string.pesdk_adjustments_title_name, ImageSource.create(R.drawable.imgly_icon_tool_adjust)),
                    new ToolItem("imgly_tool_sticker_selection", R.string.pesdk_sticker_title_name, ImageSource.create(R.drawable.imgly_icon_tool_sticker)),
                    new ToolItem("imgly_tool_text", R.string.pesdk_text_title_name, ImageSource.create(R.drawable.imgly_icon_tool_text)),
                    new ToolItem("imgly_tool_overlay", R.string.pesdk_overlay_title_name, ImageSource.create(R.drawable.imgly_icon_tool_overlay)),
                    new ToolItem("imgly_tool_frame", R.string.pesdk_frame_title_name, ImageSource.create(R.drawable.imgly_icon_tool_frame)),
                    new ToolItem("imgly_tool_brush", R.string.pesdk_brush_title_name, ImageSource.create(R.drawable.imgly_icon_tool_brush)),
                    new ToolItem("imgly_tool_focus", R.string.pesdk_focus_title_name, ImageSource.create(R.drawable.imgly_icon_tool_focus))
            );
        }


if((options.hasKey("androidForceCrop") && options.getBoolean("androidForceCrop")) || (options.hasKey("androidSingleCrop") && options.getBoolean("androidSingleCrop"))) {
// Remove default Assets and add your own aspects
    settingsList.getSettingsModel(AssetConfig.class).getAssetMap(CropAspectAsset.class).clear()
            .add(
                    new CropAspectAsset("Crop", 1536, 2730, false)
            );

  if((options.hasKey("androidForceCrop") && options.getBoolean("androidForceCrop"))) {
    settingsList.getSettingsModel(UiConfigAspect.class).setAspectList(
      new CropAspectItem("Crop", "Crop")
    );
  }
   else{
    settingsList.getSettingsModel(UiConfigAspect.class).setAspectList(
      new CropAspectItem("Crop", "Crop")
    ).setForceCropMode(
      // This prevents that the Transform tool opens at start.
      UiConfigAspect.ForceCrop.SHOW_TOOL_NEVER
    );
  }
}

        final String fontAssetsFolder = "fonts/";

        ConfigMap<FontAsset> fontAssetMap = settingsList.getSettingsModel(AssetConfig.class).getAssetMap(FontAsset.class);
        fontAssetMap.add(new FontAsset("AvenirNext-Regular", fontAssetsFolder + "AvenirNext-Regular.ttf"));
        fontAssetMap.add(new FontAsset("AceofSpades-Regular", fontAssetsFolder + "AceofSpades-Regular.otf"));
        fontAssetMap.add(new FontAsset("Aerokids", fontAssetsFolder + "Aerokids.ttf"));
        fontAssetMap.add(new FontAsset("AlphaEcho", fontAssetsFolder + "AlphaEcho.ttf"));
        fontAssetMap.add(new FontAsset("Antonio-Bold", fontAssetsFolder + "Antonio-Bold.ttf"));
        fontAssetMap.add(new FontAsset("AnuDawItalic", fontAssetsFolder + "AnuDawItalic.ttf"));
        fontAssetMap.add(new FontAsset("ArbourOblique-Regular", fontAssetsFolder + "ArbourOblique-Regular.ttf"));
        fontAssetMap.add(new FontAsset("Arcon-Rounded-Regular", fontAssetsFolder + "Arcon-Rounded-Regular.otf"));
        fontAssetMap.add(new FontAsset("Arizonia-Regular", fontAssetsFolder + "Arizonia-Regular.ttf"));
        fontAssetMap.add(new FontAsset("AvenirNext-DemiBold", fontAssetsFolder + "AvenirNext-DemiBold.ttf"));
        fontAssetMap.add(new FontAsset("AvenirNext-Medium", fontAssetsFolder + "AvenirNext-Medium.ttf"));
        fontAssetMap.add(new FontAsset("AvenirNext-Bold", fontAssetsFolder + "AvenirNext-Bold.ttf"));
        fontAssetMap.add(new FontAsset("AvenirNext-Italic", fontAssetsFolder + "AvenirNext-Italic.ttf"));
        fontAssetMap.add(new FontAsset("Bebas", fontAssetsFolder + "Bebas.ttf"));
        fontAssetMap.add(new FontAsset("BelligerentMadness", fontAssetsFolder + "BelligerentMadness.ttf"));
        fontAssetMap.add(new FontAsset("BlackJack", fontAssetsFolder + "BlackJack.otf"));
        fontAssetMap.add(new FontAsset("Bough-Condensed", fontAssetsFolder + "Bough-Condensed.otf"));
        fontAssetMap.add(new FontAsset("DancingScript-Bold", fontAssetsFolder + "DancingScript-Bold.ttf"));
        fontAssetMap.add(new FontAsset("DeValencia-Regular", fontAssetsFolder + "DeValencia-Regular.otf"));
        fontAssetMap.add(new FontAsset("Edo", fontAssetsFolder + "Edo.ttf"));
        fontAssetMap.add(new FontAsset("EnglandHandDB", fontAssetsFolder + "EnglandHandDB.ttf"));
        fontAssetMap.add(new FontAsset("EuphoriaScript-Regular", fontAssetsFolder + "EuphoriaScript-Regular.otf"));
        fontAssetMap.add(new FontAsset("firsttest", fontAssetsFolder + "firsttest.ttf"));
        fontAssetMap.add(new FontAsset("FrenteH1-Regular", fontAssetsFolder + "FrenteH1-Regular.otf"));
        fontAssetMap.add(new FontAsset("GearedSlab-Extrabold", fontAssetsFolder + "GearedSlab-Extrabold.ttf"));
        fontAssetMap.add(new FontAsset("Governor", fontAssetsFolder + "Governor.ttf"));
        fontAssetMap.add(new FontAsset("Hominis", fontAssetsFolder + "Hominis.ttf"));
        fontAssetMap.add(new FontAsset("HustleScript-Bold", fontAssetsFolder + "HustleScript-Bold.otf"));
        fontAssetMap.add(new FontAsset("HVDRowdy", fontAssetsFolder + "HVDRowdy.otf"));
        fontAssetMap.add(new FontAsset("ImpactLabel", fontAssetsFolder + "ImpactLabel.ttf"));
        fontAssetMap.add(new FontAsset("KaushanScript-Regular", fontAssetsFolder + "KaushanScript-Regular.otf"));
        fontAssetMap.add(new FontAsset("Langdon", fontAssetsFolder + "Langdon.otf"));
        fontAssetMap.add(new FontAsset("LeagueScriptThin-Regular", fontAssetsFolder + "LeagueScriptThin-Regular.otf"));
        fontAssetMap.add(new FontAsset("LeckerliOne", fontAssetsFolder + "LeckerliOne.otf"));
        fontAssetMap.add(new FontAsset("Matchbook", fontAssetsFolder + "Matchbook.otf"));
        fontAssetMap.add(new FontAsset("OceanBeach-MinorVintage", fontAssetsFolder + "OceanBeach-MinorVintage.otf"));
        fontAssetMap.add(new FontAsset("OleoScript-Bold", fontAssetsFolder + "OleoScript-Bold.ttf"));
        fontAssetMap.add(new FontAsset("Oswald-Bold", fontAssetsFolder + "Oswald-Bold.ttf"));
        fontAssetMap.add(new FontAsset("PaeteRound", fontAssetsFolder + "PaeteRound.ttf"));
        fontAssetMap.add(new FontAsset("PathwayGothicOne-Regular", fontAssetsFolder + "PathwayGothicOne-Regular.ttf"));
        fontAssetMap.add(new FontAsset("PermanentMarker", fontAssetsFolder + "PermanentMarker.ttf"));
        fontAssetMap.add(new FontAsset("Pincoyablack-Black", fontAssetsFolder + "Pincoyablack-Black.otf"));
        fontAssetMap.add(new FontAsset("Playball-Regular", fontAssetsFolder + "Playball-Regular.ttf"));
        fontAssetMap.add(new FontAsset("PorterSansBlock", fontAssetsFolder + "PorterSansBlock.otf"));
        fontAssetMap.add(new FontAsset("Quatro", fontAssetsFolder + "Quatro.otf"));
        fontAssetMap.add(new FontAsset("QuicksandDash-Regular", fontAssetsFolder + "QuicksandDash-Regular.otf"));
        fontAssetMap.add(new FontAsset("Raleway-Light", fontAssetsFolder + "Raleway-Light.ttf"));
        fontAssetMap.add(new FontAsset("Rancho", fontAssetsFolder + "Rancho.ttf"));
        fontAssetMap.add(new FontAsset("RestlessYouthScript-Bold", fontAssetsFolder + "RestlessYouthScript-Bold.otf"));
        fontAssetMap.add(new FontAsset("SixCaps", fontAssetsFolder + "SixCaps.ttf"));
        fontAssetMap.add(new FontAsset("Slukoni-Medium", fontAssetsFolder + "Slukoni-Medium.otf"));
        fontAssetMap.add(new FontAsset("SpecialElite-Regular", fontAssetsFolder + "SpecialElite-Regular.ttf"));
        fontAssetMap.add(new FontAsset("STONEHARBOUR-Regular", fontAssetsFolder + "STONEHARBOUR-Regular.otf"));
        fontAssetMap.add(new FontAsset("Sullivan-Bevel", fontAssetsFolder + "Sullivan-Bevel.otf"));
        fontAssetMap.add(new FontAsset("TradeWinds", fontAssetsFolder + "TradeWinds.ttf"));
        fontAssetMap.add(new FontAsset("TwilightScript", fontAssetsFolder + "TwilightScript.otf"));
        fontAssetMap.add(new FontAsset("UbuntuTitling-Bold", fontAssetsFolder + "UbuntuTitling-Bold.ttf"));
        fontAssetMap.add(new FontAsset("Yellowtail", fontAssetsFolder + "Yellowtail.otf"));
        fontAssetMap.add(new FontAsset("BeginningYoga", fontAssetsFolder + "BeginningYoga.ttf"));
        fontAssetMap.add(new FontAsset("YorkshireBrushScript-Regular", fontAssetsFolder + "YorkshireBrushScript-Regular.otf"));

        DataSourceIdItemList<FontItem> fontsInUiList = new DataSourceIdItemList<>();
        fontsInUiList.add(new FontItem("AvenirNext-Regular", "Avenir"));
        fontsInUiList.add(new FontItem("AceofSpades-Regular", "Ace of Spades"));
        fontsInUiList.add(new FontItem("Aerokids", "Aerokids"));
        fontsInUiList.add(new FontItem("AlphaEcho", "Alpha Echo"));
        fontsInUiList.add(new FontItem("Antonio-Bold", "Antonio"));
        fontsInUiList.add(new FontItem("AnuDawItalic", "AnuDaw"));
        fontsInUiList.add(new FontItem("ArbourOblique-Regular", "Arbour"));
        fontsInUiList.add(new FontItem("Arcon-Rounded-Regular", "Arcon"));
        fontsInUiList.add(new FontItem("Arizonia-Regular", "Arizonia"));
        fontsInUiList.add(new FontItem("AvenirNext-DemiBold", "Avenir Demi"));
        fontsInUiList.add(new FontItem("AvenirNext-Medium", "Avenir Med"));
        fontsInUiList.add(new FontItem("AvenirNext-Bold", "Avenir Bold"));
        fontsInUiList.add(new FontItem("AvenirNext-Italic", "Avenir Italic"));
        fontsInUiList.add(new FontItem("Bebas", "Bebas"));
        fontsInUiList.add(new FontItem("BelligerentMadness", "Belligerent"));
        fontsInUiList.add(new FontItem("BlackJack", "Black Jack"));
        fontsInUiList.add(new FontItem("Bough-Condensed", "Bough"));
        fontsInUiList.add(new FontItem("DancingScript-Bold", "Dancing"));
        fontsInUiList.add(new FontItem("DeValencia-Regular", "De Valencia"));
        fontsInUiList.add(new FontItem("Edo", "Edo"));
        fontsInUiList.add(new FontItem("EnglandHandDB", "England"));
        fontsInUiList.add(new FontItem("EuphoriaScript-Regular", "Euphoria"));
        fontsInUiList.add(new FontItem("firsttest", "First Test"));
        fontsInUiList.add(new FontItem("FrenteH1-Regular", "Frente H1"));
        fontsInUiList.add(new FontItem("GearedSlab-Extrabold", "Geared Slab"));
        fontsInUiList.add(new FontItem("Governor", "Governor"));
        fontsInUiList.add(new FontItem("Hominis", "Hominis"));
        fontsInUiList.add(new FontItem("HustleScript-Bold", "Hustle"));
        fontsInUiList.add(new FontItem("HVDRowdy", "HVD Rowdy"));
        fontsInUiList.add(new FontItem("ImpactLabel", "Impact"));
        fontsInUiList.add(new FontItem("KaushanScript-Regular", "Kaushan"));
        fontsInUiList.add(new FontItem("Langdon", "Langdon"));
        fontsInUiList.add(new FontItem("LeagueScriptThin-Regular", "League"));
        fontsInUiList.add(new FontItem("LeckerliOne", "Lecker"));
        fontsInUiList.add(new FontItem("Matchbook", "Matchbook"));
        fontsInUiList.add(new FontItem("OceanBeach-MinorVintage", "Ocean Beach"));
        fontsInUiList.add(new FontItem("OleoScript-Bold", "Oleo Script"));
        fontsInUiList.add(new FontItem("Oswald-Bold", "Oswald"));
        fontsInUiList.add(new FontItem("PaeteRound", "Paete"));
        fontsInUiList.add(new FontItem("PathwayGothicOne-Regular", "Pathway"));
        fontsInUiList.add(new FontItem("PermanentMarker", "Permanent"));
        fontsInUiList.add(new FontItem("Pincoyablack-Black", "Pincoya"));
        fontsInUiList.add(new FontItem("Playball-Regular", "Playball"));
        fontsInUiList.add(new FontItem("PorterSansBlock", "Porter"));
        fontsInUiList.add(new FontItem("Quatro", "Quatro"));
        fontsInUiList.add(new FontItem("QuicksandDash-Regular", "Quicksand"));
        fontsInUiList.add(new FontItem("Raleway-Light", "Raleway"));
        fontsInUiList.add(new FontItem("Rancho", "Rancho"));
        fontsInUiList.add(new FontItem("RestlessYouthScript-Bold", "Restless"));
        fontsInUiList.add(new FontItem("SixCaps", "Six Caps"));
        fontsInUiList.add(new FontItem("Slukoni-Medium", "Slukoni"));
        fontsInUiList.add(new FontItem("SpecialElite-Regular", "Special Elite"));
        fontsInUiList.add(new FontItem("STONEHARBOUR-Regular", "Stone"));
        fontsInUiList.add(new FontItem("Sullivan-Bevel", "Sullivan"));
        fontsInUiList.add(new FontItem("TradeWinds", "Trade Winds"));
        fontsInUiList.add(new FontItem("TwilightScript", "Twilight"));
        fontsInUiList.add(new FontItem("UbuntuTitling-Bold", "Ubuntu"));
        fontsInUiList.add(new FontItem("Yellowtail", "Yellowtail"));
        fontsInUiList.add(new FontItem("BeginningYoga", "Yoga"));
        fontsInUiList.add(new FontItem("YorkshireBrushScript-Regular", "Yorkshire"));

        UiConfigText uiConfigText = settingsList.getSettingsModel(UiConfigText.class);
        uiConfigText.setFontList(fontsInUiList);



        final String art="https://d1hwjrzco5rhv1.cloudfront.net/imageAssets/newartwork/";
        int total=15;
        String[] badges=new String[total];
        int i=14;
        int position=0;
        while (i <= 16)
        {
            badges[position]="frame_" + i;
            position++;
            i++;
        }
        i=19;
        while (i <= 29)
        {
            badges[position]="frame_" + i;
            position++;
            i++;
        }
            badges[position]="frame_" + 31;


        // Obtain the asset config from you settingsList
        AssetConfig assetConfig = settingsList.getConfig();
// Add Assets
        ArrayList<ImageStickerItem> badgeItems = new ArrayList<ImageStickerItem>(total);
        i=0;
        while(i<total){
        assetConfig.addAsset(
              new ImageStickerAsset(
                        badges[i],
                        ImageSource.create(Uri.parse(art + badges[i]+ ".png"))
                )
        );
            badgeItems.add(  new ImageStickerItem(badges[i], badges[i],
                    ImageSource.create(Uri.parse(art + badges[i] + ".png"))));
        i++;
        }

        total=21;
        String[] borders=new String[total];
        i=1;
        position=0;
        while (i <= 5)
        {
            borders[position]="frame_" + i;
            position++;
            i++;
        }
        i=8;
        while (i <= 10)
        {
            borders[position]="frame_" + i;
            position++;
            i++;
        }
        i=17;
        while (i <= 18)
        {
            borders[position]="frame_" + i;
            position++;
            i++;
        }
        i=32;
        while (i <= 42)
        {
            borders[position]="frame_" + i;
            position++;
            i++;
        }


        ArrayList<ImageStickerItem> borderItems = new ArrayList<ImageStickerItem>(total);
        i=0;
        while(i<total){
            assetConfig.addAsset(
                    new ImageStickerAsset(
                            borders[i],
                            ImageSource.create(Uri.parse(art + borders[i]+ ".png"))
                    )
            );
            borderItems.add(  new ImageStickerItem(borders[i], borders[i],
                    ImageSource.create(Uri.parse(art + borders[i] + ".png"))));
            i++;
        }


        total=30;
        String[] swashes=new String[total];
        i=6;
        position=0;
        while (i <= 7)
        {
            swashes[position]="frame_" + i;
            position++;
            i++;
        }
        i=43;
        while (i <= 70)
        {
            swashes[position]="frame_" + i;
            position++;
            i++;
        }

        ArrayList<ImageStickerItem> swashItems = new ArrayList<ImageStickerItem>(total);
        i=0;
        while(i<total){
            assetConfig.addAsset(
                    new ImageStickerAsset(
                            swashes[i],
                            ImageSource.create(Uri.parse(art + swashes[i]+ ".png"))
                    )
            );
            swashItems.add(  new ImageStickerItem(swashes[i], swashes[i],
                    ImageSource.create(Uri.parse(art + swashes[i] + ".png"))));
            i++;
        }


        total=73;
        String[] words=new String[total];
        i=11;
        position=0;
        while (i <= 13)
        {
            words[position]="frame_" + i;
            position++;
            i++;
        }
        i=1;
        while (i <= 35)
        {
            words[position]="text_" + i;
            position++;
            i++;
        }
        i=151;
        while (i <= 185)
        {
            words[position]="object_" + i;
            position++;
            i++;
        }
        i=32;

        ArrayList<ImageStickerItem> wordItems = new ArrayList<ImageStickerItem>(total);
        i=0;
        while(i<total){
            assetConfig.addAsset(
                    new ImageStickerAsset(
                            words[i],
                            ImageSource.create(Uri.parse(art + words[i]+ ".png"))
                    )
            );
            wordItems.add(  new ImageStickerItem(words[i], words[i],
                    ImageSource.create(Uri.parse(art + words[i] + ".png"))));
            i++;
        }


        total=150;
        String[] objects=new String[total];
        i=1;
        position=0;
        while (i <= 150)
        {
            objects[position]="object_" + i;
            position++;
            i++;
        }
        ArrayList<ImageStickerItem> objectItems = new ArrayList<ImageStickerItem>(total);
        i=0;
        while(i<total){
            assetConfig.addAsset(
                    new ImageStickerAsset(
                            objects[i],
                            ImageSource.create(Uri.parse(art + objects[i]+ ".png"))
                    )
            );
            objectItems.add(  new ImageStickerItem(objects[i], objects[i],
                    ImageSource.create(Uri.parse(art + objects[i] + ".png"))));
            i++;
        }




        UiConfigSticker uiConfigSticker = settingsList.getSettingsModel(UiConfigSticker.class);
        uiConfigSticker.setStickerLists(
                StickerPackEmoticons.getStickerCategory(),
                StickerPackShapes.getStickerCategory(),
                new StickerCategoryItem(
                        "badges",
                        "Badges",
                        ImageSource.create(Uri.parse(art + "categories/badges.png")),
                        badgeItems
                ),
                new StickerCategoryItem(
                        "borders",
                        "Borders",
                        ImageSource.create(Uri.parse(art + "categories/borders.png")),
                        borderItems
                ),
                new StickerCategoryItem(
                        "swashes",
                        "Swashes",
                        ImageSource.create(Uri.parse(art + "categories/swashes.png")),
                        swashItems
                ),
                new StickerCategoryItem(
                        "words",
                        "Words",
                        ImageSource.create(Uri.parse(art + "categories/words.png")),
                        wordItems
                ),
                new StickerCategoryItem(
                        "objects",
                        "Objects",
                        ImageSource.create(Uri.parse(art + "categories/outdoor.png")),
                        objectItems
                )

        );





      final String overlays="https://d1hwjrzco5rhv1.cloudfront.net/imageAssets/photoeditor/";
      assetConfig.addAsset(
        new OverlayAsset(
          "overlay_painting",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_painting.jpg")),
          BlendMode.OVERLAY,
          1f
        ),
        new OverlayAsset(
          "overlay_grainy",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_grain.jpg")),
          BlendMode.OVERLAY,
          1f
        ),
        new OverlayAsset(
          "overlay_rain",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_rain.jpg")),
          BlendMode.OVERLAY,
          1f
        ),
        new OverlayAsset(
          "overlay_hearts",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_hearts.jpg")),
          BlendMode.SCREEN,
          1f
        ),
        new OverlayAsset(
          "overlay_wall",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_wall2.jpg")),
          BlendMode.OVERLAY,
          1f
        ),
        new OverlayAsset(
          "overlay_tj",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_tj4.jpg")),
          BlendMode.OVERLAY,
          1f
        )
        );


      UiConfigOverlay uiConfigOverlay = settingsList.getSettingsModel(UiConfigOverlay.class);
// Add Overlay items to the UI
      uiConfigOverlay.setOverlayList(
        new OverlayItem(
          OverlayAsset.NONE_BACKDROP_ID,
          R.string.pesdk_overlay_asset_none,
          ImageSource.create(R.drawable.imgly_icon_option_overlay_none)
        ),
        new OverlayItem(
          "imgly_overlay_vintage",
          "Vintage",
          ImageSource.create(R.drawable.imgly_overlay_vintage_thumb)
        ),
        new OverlayItem(
          "overlay_painting",
          "Painting",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_painting_thumb.jpg"))
        ),
        new OverlayItem(
          "overlay_grainy",
          "Grainy",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_grain_thumb.jpg"))
        ),
        new OverlayItem(
          "overlay_rain",
          "Rain",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_rain_thumb.jpg"))
        ),
        new OverlayItem(
          "overlay_hearts",
          "Hearts",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_hearts_thumb.jpg"))
        ),
        new OverlayItem(
          "overlay_wall",
          "Wall",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_wall2_thumb.jpg"))
        ),
      new OverlayItem(
          "imgly_overlay_lightleak1",
          "Lightleak",
          ImageSource.create(R.drawable.imgly_overlay_lightleak1_thumb)
        ),
        new OverlayItem(
          "overlay_tj",
          "The Jump",
          ImageSource.create(Uri.parse(overlays + "imgly_overlay_tj_thumb.jpg"))
        )

      );


        return settingsList;
    }

    @Override
    public String getName() {
        return "PESDK";
    }

    @Nullable
    @Override
    public Map<String, Object> getConstants() {
        final Map<String, java.lang.Object> constants = new HashMap<String, Object>();
        constants.put("transformTool", transformTool);
        constants.put("filterTool", filterTool);
        constants.put("focusTool", focusTool);
        constants.put("adjustTool", adjustTool);
        constants.put("textTool", textTool);
        constants.put("stickerTool", stickerTool);
        constants.put("overlayTool", overlayTool);
        constants.put("brushTool", brushTool);
        constants.put("magic", magic);
        constants.put("backgroundColorCameraKey", backgroundColorCameraKey);
        constants.put("backgroundColorEditorKey", backgroundColorEditorKey);
        constants.put("backgroundColorMenuEditorKey", backgroundColorMenuEditorKey);
        constants.put("cameraRollAllowedKey", cameraRollAllowedKey);
        constants.put("showFiltersInCameraKey", showFiltersInCameraKey);

        return constants;
    }

    @ReactMethod
    public void openEditor(@NonNull String image, ReadableArray features, ReadableMap options, final Promise promise) {
        if (getCurrentActivity() == null) {
           promise.reject(E_ACTIVITY_DOES_NOT_EXIST, "Activity does not exist");
        } else {
            mPESDKPromise = promise;

            SettingsList settingsList = buildConfig(options, features, image.toString());

            new PhotoEditorBuilder(getCurrentActivity())
                    .setSettingsList(settingsList)
                    .startActivityForResult(getCurrentActivity(), RESULT_CODE_PESDK);
        }
    }

    @ReactMethod
    public void openCamera(ReadableArray features, ReadableMap options, final Promise promise) {
        if (getCurrentActivity() == null) {
            promise.reject(E_ACTIVITY_DOES_NOT_EXIST, "Activity does not exist");
        } else {
            mPESDKPromise = promise;

            SettingsList settingsList = buildConfig(options, features, null);

            new CameraPreviewBuilder(getCurrentActivity())
                    .setSettingsList(settingsList)
                    .startActivityForResult(getCurrentActivity(), RESULT_CODE_PESDK);
        }
    }

}
