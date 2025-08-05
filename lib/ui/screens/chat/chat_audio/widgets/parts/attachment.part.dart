part of "../chat_widget.dart";

class AttachmentMessage extends StatefulWidget {
  final String url;
  final bool? showFileName;

  const AttachmentMessage(
      {super.key, required this.url, this.showFileName = true});

  @override
  State<AttachmentMessage> createState() => _AttachmentMessageState();
}

class _AttachmentMessageState extends State<AttachmentMessage> {
  bool isFileDownloading = false;
  double persontage = 0;

  String getExtentionOfFile() {
    return widget.url.toString().split(".").last;
  }

  String getFileName() {
    return widget.url.toString().split("/").last;
  }

  Future<void> openImage() async {
    try {
      String filePath;

      if (widget.url.startsWith('http')) {
        // 🔹 It's a network image — download it using Dio
        final dio = Dio();
        final dir = await getTemporaryDirectory();
        filePath = '${dir.path}/downloaded_image.jpg';

        await dio.download(
          widget.url,
          filePath,
          options: Options(responseType: ResponseType.bytes),
        );
      } else {
        filePath = widget.url;
      }

      // 🔹 Open the file
      final result = await OpenFilex.open(filePath);
    } catch (e) {
      print('Error opening image: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () async {
            await openImage();
          },
          child: Container(
            height: 50,
            width: 50,
            alignment: AlignmentDirectional.center,
            decoration: BoxDecoration(
                color: context.color.textLightColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: context.color.borderColor, width: 1.8)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (persontage != 0 && persontage != 1) ...[
                  Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 1.7,
                        color: context.color.territoryColor,
                        value: persontage,
                      ),
                      const Icon(Icons.close)
                    ],
                  ),
                ] else ...[
                  CustomText(getExtentionOfFile().toString().toUpperCase()),
                  Icon(
                    Icons.download,
                    size: 14,
                    color: context.color.territoryColor,
                  )
                ]
              ],
            ),
          ),
        ),
        if (widget.showFileName ?? true) ...[
          const SizedBox(
            width: 5,
          ),
          Expanded(
            child: Container(
              height: 50,
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CustomText(
                    getFileName().toString(),
                    maxLines: 1,
                  )),
            ),
          ),
        ]
      ],
    );
  }
}
