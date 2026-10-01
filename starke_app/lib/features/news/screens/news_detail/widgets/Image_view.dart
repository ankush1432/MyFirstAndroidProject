import 'package:flutter/material.dart';
import 'package:starke_app/commons/widgets/network_image.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';

class ImageView extends StatefulWidget {
  final NewsModel? model;
  final BreakingNewsModel? breakModel;
  final bool isFromBreak;

  const ImageView(
      {super.key, this.model, this.breakModel, required this.isFromBreak});

  @override
  ImageViewState createState() => ImageViewState();
}

class ImageViewState extends State<ImageView> {
  List<String> allImage = [];
  int _curSlider = 0;

  late final PageController _pageController;

  // static double _thumbSize = 60;
  // static double _thumbSpacing = 8;
  // static double _thumbPadding = 12;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    allImage.clear();
    if (!widget.isFromBreak) {
      allImage.add(widget.model!.image ?? "");
      if (widget.model!.imageDataList!.isNotEmpty) {
        for (int i = 0; i < widget.model!.imageDataList!.length; i++) {
          allImage.add(widget.model!.imageDataList![i].otherImage ?? "");
        }
      }
    } else {
      allImage.add(widget.breakModel!.image ?? "");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget imageView() {
    final imageHeight = MediaQuery.of(context).size.height * 0.25;  

    return SizedBox(
      height: imageHeight,
      width: double.maxFinite,
      child: !widget.isFromBreak
          ? PageView.builder(
              controller: _pageController,
              itemCount: allImage.length,
              onPageChanged: (index) {
                setState(() {
                  _curSlider = index;
                });
              },
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      Routes.imagePreview,
                      arguments: {
                        "index": index,
                        "imgList": allImage,
                      },
                    );
                  },
                  child: CustomNetworkImage(
                    networkImageUrl: allImage[index],
                    width: double.infinity,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    isVideo: false,
                  ),
                );
              },
            )
          : CustomNetworkImage(
              networkImageUrl: widget.breakModel!.image ?? "",
              width: double.infinity,
              height: imageHeight,
              isVideo: false,
              fit: BoxFit.cover),
    );
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  Widget imageSliderDot() {
    if (!widget.isFromBreak && allImage.length > 1) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: map<Widget>(allImage, (index, url) {
          return Container(
            width: _curSlider == index ? 10 : 8,
            height: _curSlider == index ? 10 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(
                _curSlider == index ? 1 : .5,
              ),
            ),
          );
        }),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        imageView(),
        Positioned(bottom: 16, left: 0, right: 0, child: imageSliderDot()),
      ],
    );
  }
}
