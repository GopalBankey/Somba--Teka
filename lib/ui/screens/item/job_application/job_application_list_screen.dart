import 'package:SombaTeka/data/cubits/item/job_application/change_job_application_status_cubit.dart';
import 'package:SombaTeka/data/cubits/item/job_application/fetch_job_application_cubit.dart';
import 'package:SombaTeka/data/model/item/job_application.dart';
import 'package:SombaTeka/ui/screens/chat/chat_audio/widgets/chat_widget.dart';
import 'package:SombaTeka/ui/screens/home/home_screen.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_data_found.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_internet.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/api.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/helper_utils.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

int currentJobItemId = 0;

class JobApplicationListScreen extends StatefulWidget {
  final int itemId;
  final bool? isMyJobApplications;

  const JobApplicationListScreen(
      {Key? key, required this.itemId, this.isMyJobApplications = false})
      : super(key: key);

  @override
  _JobApplicationListScreenState createState() =>
      _JobApplicationListScreenState();

  static Route route(RouteSettings routeSettings) {
    Map args = routeSettings.arguments as Map;
    return MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => ChangeJobApplicationStatusCubit(),
                ),
              ],
              child: JobApplicationListScreen(
                itemId: args['itemId'] as int,
                isMyJobApplications: args['isMyJobApplications'] ?? false,
              ),
            ));
  }
}

class _JobApplicationListScreenState extends State<JobApplicationListScreen> {
  late final ScrollController _pageScrollController = ScrollController();
  List<JobApplication> applications = [];

  @override
  void initState() {
    currentJobItemId = widget.itemId;
    if (HiveUtils.isUserAuthenticated()) {
      context.read<FetchJobApplicationCubit>().fetchApplications(
          itemId: widget.itemId,
          isMyJobApplications: widget.isMyJobApplications ?? false);
      _pageScrollController.addListener(_pageScroll);
    }

    super.initState();
  }

  void _pageScroll() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchJobApplicationCubit>().hasMoreData()) {
        context.read<FetchJobApplicationCubit>().fetchMyMoreapplications(
            itemId: widget.itemId,
            isMyJobApplications: widget.isMyJobApplications ?? false);
      }
    }
  }

  @override
  void dispose() {
    currentJobItemId = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: UiUtils.buildAppBar(context,
            title: widget.isMyJobApplications == true
                ? "myJobApplications".translate(context)
                : "jobApplications".translate(context),
            showBackButton: true),
        body: BlocConsumer<FetchJobApplicationCubit, FetchJobApplicationState>(
            listener: (context, state) {
          if (state is FetchJobApplicationSuccess) {
            applications = state.applications;
          }
        }, builder: (context, state) {
          if (state is FetchJobApplicationInProgress) {
            return Center(
                child: CircularProgressIndicator(
              color: context.color.territoryColor,
            ));
          }

          if (state is FetchJobApplicationFailed) {
            if (state.error is ApiException) {
              if (state.error == "no-internet") {
                return NoInternet(
                  onRetry: () {
                    context.read<FetchJobApplicationCubit>().fetchApplications(
                        itemId: widget.itemId,
                        isMyJobApplications:
                            widget.isMyJobApplications ?? false);
                  },
                );
              }
            }

            return const SomethingWentWrong();
          }

          if (state is FetchJobApplicationSuccess) {
            if (state.applications.isEmpty) {
              return NoDataFound(
                mainMessage: widget.isMyJobApplications == true
                    ? "nodatafound".translate(context)
                    : "noJobsFoundForThisAd".translate(context),
                onTap: () {
                  context.read<FetchJobApplicationCubit>().fetchApplications(
                      itemId: widget.itemId,
                      isMyJobApplications: widget.isMyJobApplications ?? false);
                },
              );
            }
            return BlocListener<ChangeJobApplicationStatusCubit,
                ChangeJobApplicationStatusState>(
              listener: (context, state) {
                if (state is ChangeJobApplicationStatusSuccess) {
                  HelperUtils.showSnackBarMessage(context, state.message);
                  setState(() {
                    final index =
                        applications.indexWhere((app) => app.id == state.id);
                    if (index != -1) {
                      applications[index].status = state.status;
                    }
                  });
                } else if (state is ChangeJobApplicationStatusFailure) {
                  HelperUtils.showSnackBarMessage(context, state.errorMessage);
                }
              },
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      controller: _pageScrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: sidePadding,
                        vertical: 8,
                      ),
                      itemCount: applications.length,
                      itemBuilder: (context, index) {
                        final app = applications[index];
                        return Card(
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          shadowColor: Colors.grey.withValues(alpha: 0.5),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isMyJobApplications == true
                                      ? '${"adTitle".translate(context)}: ${app.item?.name ?? ''}'
                                      : '${"fullName".translate(context)}: ${app.fullName}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, height: 2),
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                ),
                                Text(
                                  widget.isMyJobApplications == true
                                      ? '${"recruiter".translate(context)}: ${app.recruiter?.name ?? ''}'
                                      : '${"emailAddress".translate(context)}: ${app.email}',
                                  style: TextStyle(height: 2),
                                ),
                                if (widget.isMyJobApplications == false)
                                  Text(
                                    '${"mobileNumberLbl".translate(context)}: ${app.mobile}',
                                    style: TextStyle(height: 2),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  spacing: 10,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (app.resume != null &&
                                        app.resume!.isNotEmpty)
                                      Expanded(
                                          child: AttachmentMessage(
                                        url: app.resume!,
                                        showFileName: false,
                                      )),
                                    if (widget.isMyJobApplications == false &&
                                        app.status == 'pending')
                                      BlocBuilder<
                                          ChangeJobApplicationStatusCubit,
                                          ChangeJobApplicationStatusState>(
                                        builder: (context, state) {
                                          return IgnorePointer(
                                            ignoring: state
                                                is ChangeJobApplicationStatusInProgress,
                                            child: SizedBox(
                                              height: 30,
                                              child: Row(
                                                spacing: 10,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  acceptRejectButtonWidget(
                                                      'Accept',
                                                      Icons.check,
                                                      app.id,
                                                      'accepted'),
                                                  acceptRejectButtonWidget(
                                                      'reject',
                                                      Icons.close,
                                                      app.id,
                                                      'rejected'),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    else
                                      Text(
                                        app.status?.toUpperCase() ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: app.status == 'accepted'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (state.isLoadingMore) UiUtils.progress()
                ],
              ),
            );
          }
          return Container();
        }));
  }

  Widget acceptRejectButtonWidget(
      String btnTitle, IconData icon, int appid, String updateStatus) {
    return ElevatedButton.icon(
      onPressed: () => updateApplicationStatus(appid, updateStatus),
      icon: Icon(icon),
      label: Text(btnTitle.translate(context)),
      style: ElevatedButton.styleFrom(
        backgroundColor: updateStatus == 'accepted' ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> updateApplicationStatus(int id, String newStatus) async {
    context
        .read<ChangeJobApplicationStatusCubit>()
        .changeJobApplicationStatus(id: id, status: newStatus);
  }
}
