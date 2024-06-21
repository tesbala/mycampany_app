import 'package:animate_do/animate_do.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:floating/floating.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lofiii/di/dependency_injection.dart';
import 'package:lofiii/logic/cubit/send_current_playing_music_data_to_player_screen/send_music_data_to_player_cubit.dart';
import 'package:lofiii/logic/cubit/theme_mode/theme_mode_cubit.dart';
import 'package:lofiii/logic/cubit/youtube_music_player/youtube_music_player_cubit.dart';
import 'package:lofiii/utils/format_duration.dart';
import 'package:one_context/one_context.dart';
import 'package:pod_player/pod_player.dart';
import 'package:signals/signals_flutter.dart';
import 'package:signals/signals_flutter_extended.dart';

import '../../../logic/cubit/chnage_system_volume/chnage_system_volume_cubit.dart';
import '../../widgets/my_youtube_video_player_widget/my_youtube_video_player_widget.dart';

class YouTubeMusicPlayerPage extends StatelessWidget {
  YouTubeMusicPlayerPage({
    super.key,
  });

  final videoPosition = signal(0);
  final videoTotalDuration = signal(0);
  final videoState = signal(PodVideoState.loading);
  final videoIsBuffering = signal(true);
  final floating = locator.get<Floating>();



  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      bool potrait = orientation == Orientation.portrait;
      bool landscape = orientation == Orientation.landscape;
      return PopScope(
        canPop: true,
        onPopInvoked: (bool) async {
          if (orientation == Orientation.landscape) {
            await SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitUp]);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                overlays: SystemUiOverlay.values);
          }
        },
        child: BlocBuilder<ThemeModeCubit, ThemeModeState>(
            builder: (context, themeState) {
          return BlocBuilder<YoutubeMusicPlayerCubit, YoutubeMusicPlayerState>(
            builder: (context, playerState) {
              if (playerState is YoutubeMusicPlayerSuccessState) {
                playerState.controller.addListener(() {
                  videoPosition.value =
                      playerState.controller.currentVideoPosition.inSeconds;
                  videoTotalDuration.value =
                      playerState.controller.totalVideoLength.inSeconds;
                  videoState.value = playerState.controller.videoState;
                  videoIsBuffering.value =
                      playerState.controller.isVideoBuffering;
                });

                return Scaffold(
                  backgroundColor: Colors.black,
                  extendBodyBehindAppBar: true,

                  ///!---------------------------- body
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      ///?--------------------------------------  Player
                      GestureDetector(
                        ///!-------- Show Player Buttons
                        onTap: () async {
                          context
                              .read<YoutubeMusicPlayerCubit>()
                              .showPlayerButtonsToggle(state: playerState);
                        },

                        ///!-----------    Play Pause Toggle
                        onDoubleTap: () {
                          playerState.controller.togglePlayPause();
                        },

                        onVerticalDragUpdate: (details) {
                          ///!----------  Change System Volume
                          _changeVolume(details);
                        },

                        onHorizontalDragUpdate: (details) async {
                          ///!-------------  Change Video Position
                          _changeVideoPosition(context, details, playerState);
                        },
                        child: Container(
                          height: 1.sh,
                          width: 1.sw,
                          color: Colors.black,

                          ///?-------------------------------------------------------////
                          ////!--------------------------  Player --------------------///
                          ///?-------------------------------------------------------////
                          child: const MyYouTubeVideoPlayerWidget(
                          ),
                        ),
                      ),

                      ///!---------------------  Back Button
                      Visibility(
                        visible: playerState.showPlayerButtons,
                        child: Positioned(
                          left: 0.04.sw,
                          top: 0.08.sh,
                          child: SlideInLeft(
                            child: IconButton(
                              onPressed: () async {

                                if (orientation == Orientation.landscape) {
                                  await SystemChrome.setPreferredOrientations(
                                      [DeviceOrientation.portraitUp]);
                                  SystemChrome.setEnabledSystemUIMode(
                                      SystemUiMode.manual,
                                      overlays: SystemUiOverlay.values);
                                }
                                OneContext().pop();
                              },
                              icon: Icon(
                                CupertinoIcons.back,
                                color: Colors.white,
                                size: potrait ? 30.sp : 16.sp,
                              ),
                            ),
                          ),
                        ),
                      ),

                      ///!------------------------------- Device Orientation
                      Visibility(
                        visible: playerState.showPlayerButtons,
                        child: Positioned(
                          top: 0.08.sh,
                          right: 0.03.sw,
                          child: SlideInRight(
                            child: IconButton(
                              onPressed: () async {
                                await _orientationButtonOnTap(orientation);
                              },
                              icon: const Icon(
                                Icons.screen_rotation,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      ///!------------------------------- Floating
                      Visibility(
                        visible: playerState.showPlayerButtons,
                        child: Positioned(
                          top: 0.08.sh,
                          right: 0.13.sw,
                          child: SlideInRight(
                            child: IconButton(
                              onPressed: () async {
                                await _floatingButtonOnTap(playerState);
                              },
                              icon: const Icon(
                                Icons.picture_in_picture,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      ///?-------------- Show Current Video Position on Horizontal Dragging Only
                      Visibility(
                        visible: playerState.showVideoPositionOnHDragging,
                        child: Positioned(
                          top: potrait ? 0.3.sh : 0.025.sh,
                          width: 1.sw,
                          child: Center(
                            child: Text(
                              " ${FormatDuration.format(Duration(seconds: watchSignal(context, videoPosition)))}/${FormatDuration.format(Duration(seconds: watchSignal(context, videoTotalDuration)))}",
                              style: TextStyle(
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                        color: Colors.black87,
                                        offset: Offset.zero)
                                  ],
                                  fontSize: potrait ? 25.sp : 15.sp),
                            ),
                          ),
                        ),
                      ),

                      ///!----------------------------- Player Buttons ----------------------------//

                      _potraitPlayerButtons(playerState, playerState.controller,
                          orientation, context),

                      ///!---------------------------- Landscape Player Buttons ---------------
                      _landscapePlayerButtons(playerState, landscape, context),
                    ],
                  ),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          );
        }),
      );
    });
  }

  ///?-----------------------------------------------------------------------------//
  ///!--------------------------- M E T H O D S ----------------------------------///
  ///--------------------------------------------------------------------------///

  ///?--------------------------for P O T R A I T -------------------------------///
  ///!---------------------- Player Buttons Method -------------------------------///
  Positioned _potraitPlayerButtons(YoutubeMusicPlayerSuccessState playerState,
      PodPlayerController controller, orientation, context) {
    return Positioned(
      bottom: 0.05.sh,
      width: 1.sw,
      child: Visibility(
        visible: playerState.showPlayerButtons &&
            orientation == Orientation.portrait,
        child: SlideInUp(
          duration: const Duration(milliseconds: 100),
          child: Column(
            children: [
              ///!---------- Slider -----------//
              SliderTheme(
                data: _sliderThemeData(),
                child: Slider(
                  min: 0,
                  max: playerState.controller.totalVideoLength.inSeconds
                      .toDouble(),
                  value: watchSignal(context, videoPosition).toDouble(),
                  onChanged: (value) {
                    playerState.controller
                        .videoSeekTo(Duration(seconds: value.toInt()));
                  },
                ),
              ),

              ///!--------------- Video Position Text & Duration Text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.sp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ///!------------ Position
                    Text(
                      FormatDuration.format(Duration(
                              seconds: watchSignal(context, videoPosition)))
                          .toString(),
                      style: const TextStyle(color: Colors.white),
                    ),

                    ///!---------Duration
                    Text(
                      FormatDuration.format(Duration(
                              seconds:
                                  watchSignal(context, videoTotalDuration)))
                          .toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),

              ///!------------------------------------ Buttons ---------------------//
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ///!--------------Previous Music Button
                  BlocBuilder<CurrentlyPlayingMusicDataToPlayerCubit,
                      FetchCurrentPlayingMusicDataToPlayerState>(
                    builder: (context, fetchState) {
                      return IconButton(
                          onPressed: () {
                            if (fetchState.musicIndex > 0) {
                              backwardButtonClicked(
                                  fetchState, controller, playerState);
                            }
                          },
                          icon: Icon(
                            Icons.skip_previous,
                            color: fetchState.musicIndex > 0
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            size: 40.sp,
                          ));
                    },
                  ),

                  ///!------------- Backward Button ---------///
                  IconButton(
                    onPressed: () {
                      playerState.controller
                          .videoSeekBackward(const Duration(seconds: 10));
                    },
                    icon: Icon(
                      Icons.replay_10_outlined,
                      color: Colors.white,
                      size: 40.sp,
                    ),
                  ),

                  ///!------------------- Play Pause Button -----------///
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ///!---------If Loading
                      if (watchSignal(context, videoIsBuffering))
                        CircularProgressIndicator(
                          strokeWidth: 10.sp,
                          color: Colors.white,
                        ),
                      IconButton(
                        onPressed: () {
                          playerState.controller.togglePlayPause();
                        },
                        icon: Icon(
                          watchSignal(context, videoState) ==
                                  PodVideoState.playing
                              ? EvaIcons.pauseCircle
                              : EvaIcons.playCircle,
                          color: Colors.white,
                          size: 45.sp,
                        ),
                      ),
                    ],
                  ),

                  ///!------------- Forward Button ---------///
                  IconButton(
                    onPressed: () {
                      playerState.controller
                          .videoSeekForward(const Duration(seconds: 10));
                    },
                    icon: Icon(
                      Icons.forward_10_outlined,
                      color: Colors.white,
                      size: 40.sp,
                    ),
                  ),

                  ///!--------------Next Music Button
                  BlocBuilder<CurrentlyPlayingMusicDataToPlayerCubit,
                      FetchCurrentPlayingMusicDataToPlayerState>(
                    builder: (context, fetchState) {
                      return IconButton(
                          onPressed: () {
                            if (fetchState.musicIndex <
                                fetchState.youtubeMusicList.length) {
                              nextMusicButtonClicked(
                                  fetchState, controller, playerState);
                            }
                          },
                          icon: Icon(
                            Icons.skip_next,
                            color: fetchState.musicIndex <
                                    fetchState.youtubeMusicList.length
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            size: 40.sp,
                          ));
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///?--------------------------for L A N D S C A P E -------------------------------///
  ///!---------------------- Player Buttons Method -------------------------------///
  Visibility _landscapePlayerButtons(YoutubeMusicPlayerSuccessState playerState,
      bool landscape, BuildContext context) {
    return Visibility(
      visible: playerState.showPlayerButtons && landscape,
      child: Stack(
        children: [
          Center(
            child:

                ///!------------------------------------ Buttons ---------------------//
                Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ///!------------- Backward Button ---------///
                IconButton(
                  onPressed: () {
                    playerState.controller
                        .videoSeekBackward(const Duration(seconds: 10));
                  },
                  icon: Icon(
                    Icons.replay_10_outlined,
                    color: Colors.white,
                    size: 25.sp,
                  ),
                ),
                Gap(0.02.sw),

                ///!------------------- Play Pause Button -----------///
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ///!---------If Loading
                    if (watchSignal(context, videoIsBuffering))
                      CircularProgressIndicator(
                        strokeWidth: 7.sp,
                        color: Colors.white,
                      ),
                    IconButton(
                      onPressed: () {
                        playerState.controller.togglePlayPause();
                      },
                      icon: Icon(
                        watchSignal(context, videoState) ==
                                PodVideoState.playing
                            ? EvaIcons.pauseCircle
                            : EvaIcons.playCircle,
                        color: Colors.white,
                        size: 25.sp,
                      ),
                    ),
                  ],
                ),

                Gap(0.02.sw),

                ///!------------- Forward Button ---------///
                IconButton(
                  onPressed: () {
                    playerState.controller
                        .videoSeekForward(const Duration(seconds: 10));
                  },
                  icon: Icon(
                    Icons.forward_10_outlined,
                    color: Colors.white,
                    size: 25.sp,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0.02.sh,
            width: 1.sw,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SlideInUp(
                duration: const Duration(milliseconds: 100),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ///!---------- Slider -----------//
                    SliderTheme(
                      data: _sliderThemeData(),
                      child: Slider(
                        min: 0,
                        max: playerState.controller.totalVideoLength.inSeconds
                            .toDouble(),
                        value: watchSignal(context, videoPosition).toDouble(),
                        onChanged: (value) {
                          playerState.controller
                              .videoSeekTo(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),

                    ///!--------------- Video Position Text & Duration Text
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.sp),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ///!------------ Position
                          Text(
                            FormatDuration.format(Duration(
                                    seconds:
                                        watchSignal(context, videoPosition)))
                                .toString(),
                            style: const TextStyle(color: Colors.white),
                          ),

                          ///!---------Duration
                          Text(
                            FormatDuration.format(Duration(
                                    seconds: watchSignal(
                                        context, videoTotalDuration)))
                                .toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  ///?--------------------------Floating Button On Tap-------------------------------///
  ///-------------------------------------- ---------------------------------------///
  Future<void> _floatingButtonOnTap(
      YoutubeMusicPlayerSuccessState playerState) async {
    final canUsePiP = await floating.isPipAvailable;

    if (canUsePiP) {
      await floating.enable();
      OneContext()
          .context!
          .read<YoutubeMusicPlayerCubit>()
          .hidePlayerButtons(state: playerState);
    }
  }

  ///?--------------------------Orientation Button On Tap-------------------------------///
  ///-------------------------------------- ---------------------------------------///
  Future<void> _orientationButtonOnTap(Orientation orientation) async {
    if (orientation == Orientation.portrait) {
      ///----- Set Device Orientation to Landscape Mode
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeRight]);

      ///----- Hide Status Bar Values
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    } else {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    }
  }

  ///?--------------------------Change Volume -------------------------------///
  ///-------------------------------------- ---------------------------------------///
  void _changeVolume(DragUpdateDetails details) {
    OneContext()
        .context!
        .read<ChangeSystemVolumeCubit>()
        .change(details: details, context: OneContext().context!);
  }

  ///?-------------------------- Change Video Position On Horizontal Dragging-------------------------------///
  ///-------------------------------------- ---------------------------------------///
  void _changeVideoPosition(BuildContext context, DragUpdateDetails details,
      YoutubeMusicPlayerSuccessState playerState) {
    double screenWidth = MediaQuery.of(context).size.width;
    double dragPercent = details.primaryDelta! / screenWidth;
    int seekSeconds =
        (playerState.controller.totalVideoLength.inSeconds * dragPercent)
            .toInt();

    int newSeekPosition =
        playerState.controller.currentVideoPosition.inSeconds + seekSeconds;
    newSeekPosition = newSeekPosition.clamp(
        0, playerState.controller.totalVideoLength.inSeconds);

    playerState.controller.videoSeekTo(Duration(seconds: newSeekPosition));
    updateWidgetsSignals(OneContext().context!);
    context
        .read<YoutubeMusicPlayerCubit>()
        .showCurrentPositionOnHorizontalDragging(state: playerState);
  }

  ///?--------------------------Next Music Button On Tap-------------------------------///
  ///-------------------------------------- ---------------------------------------///
  void nextMusicButtonClicked(
      FetchCurrentPlayingMusicDataToPlayerState fetchState,
      PodPlayerController controller,
      YoutubeMusicPlayerSuccessState playerState) {
    int index = fetchState.musicIndex;
    if (index < fetchState.youtubeMusicList.length) {
      index++;

      OneContext()
          .context!
          .read<YoutubeMusicPlayerCubit>()
          .hidePlayerButtons(state: playerState);



      videoPosition.value = 0;
      videoTotalDuration.value = 0;
      controller.changeVideo(
          playVideoFrom: PlayVideoFrom.youtube(
              fetchState.youtubeMusicList[index].videoId.toString()));




      OneContext()
          .context!
          .read<CurrentlyPlayingMusicDataToPlayerCubit>()
          .sendYouTubeDataToPlayer(
              youtubeList: fetchState.youtubeMusicList, musicIndex: index);
    }
  }

  ///?--------------------------Previous Button On Tap-------------------------------///
  ///-------------------------------------- ---------------------------------------///
  void backwardButtonClicked(
      FetchCurrentPlayingMusicDataToPlayerState fetchState,
      PodPlayerController controller,
      YoutubeMusicPlayerSuccessState playerState) {
    int index = fetchState.musicIndex;
    if (index > 0) {
      index--;

      OneContext()
          .context!
          .read<YoutubeMusicPlayerCubit>()
          .hidePlayerButtons(state: playerState);

      videoPosition.value = 0;
      videoTotalDuration.value = 0;
      controller.changeVideo(
          playVideoFrom: PlayVideoFrom.youtube(
              fetchState.youtubeMusicList[index].videoId.toString()));
      OneContext()
          .context!
          .read<CurrentlyPlayingMusicDataToPlayerCubit>()
          .sendYouTubeDataToPlayer(
              youtubeList: fetchState.youtubeMusicList, musicIndex: index);
    }
  }

  ///!-------------------  Slider Theme
  SliderThemeData _sliderThemeData() {
    return SliderThemeData(
        activeTickMarkColor: Colors.white,
        activeTrackColor: Colors.white,
        trackHeight: 0.015.sh,
        thumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.withOpacity(0.5));
  }
}
