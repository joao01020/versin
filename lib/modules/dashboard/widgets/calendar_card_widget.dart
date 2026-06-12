import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';

/// [CalendarCardWidget] renders the dark interactive scheduler grid and upcoming tasks.
class CalendarCardWidget
    extends
        StatelessWidget {
  final DashboardController controller;
  final VoidCallback onStateChanged;
  final VoidCallback onAddAppointmentTap;

  const CalendarCardWidget({
    super.key,
    required this.controller,
    required this.onStateChanged,
    required this.onAddAppointmentTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    // Local filter based on current selected date parameters
    final List<
      Map<
        String,
        dynamic
      >
    >
    filteredAppointments = controller.appointments.where(
      (
        element,
      ) {
        return element['day'] ==
                controller.selectedDay &&
            element['month'] ==
                controller.focusedDay.month &&
            element['year'] ==
                controller.focusedDay.year;
      },
    ).toList();

    final int daysInMonth = DateTime(
      controller.focusedDay.year,
      controller.focusedDay.month +
          1,
      0,
    ).day;
    final int firstDayOffset =
        DateTime(
          controller.focusedDay.year,
          controller.focusedDay.month,
          1,
        ).weekday %
        7;

    final List<
      String
    >
    monthsNames = [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro",
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: controller.calendarBg,
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () {
                    controller.toggleCalendarExpanded();
                    onStateChanged();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: controller.calendarPurpleAccent,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Theme(
                        data:
                            Theme.of(
                              context,
                            ).copyWith(
                              canvasColor: controller.calendarBg,
                            ),
                        child: DropdownButtonHideUnderline(
                          child: SizedBox(
                            height: 24,
                            child:
                                DropdownButton<
                                  int
                                >(
                                  value: controller.focusedDay.month,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white38,
                                    size: 16,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onChanged:
                                      (
                                        int? newMonth,
                                      ) {
                                        if (newMonth !=
                                            null) {
                                          controller.updateFocusedMonth(
                                            newMonth,
                                          );
                                          onStateChanged();
                                        }
                                      },
                                  items:
                                      List.generate(
                                        12,
                                        (
                                          index,
                                        ) =>
                                            index +
                                            1,
                                      ).map(
                                        (
                                          int monthNum,
                                        ) {
                                          return DropdownMenuItem<
                                            int
                                          >(
                                            value: monthNum,
                                            child: Text(
                                              monthsNames[monthNum -
                                                  1],
                                            ),
                                          );
                                        },
                                      ).toList(),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Theme(
                        data:
                            Theme.of(
                              context,
                            ).copyWith(
                              canvasColor: controller.calendarBg,
                            ),
                        child: DropdownButtonHideUnderline(
                          child: SizedBox(
                            height: 24,
                            child:
                                DropdownButton<
                                  int
                                >(
                                  value: controller.focusedDay.year,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white38,
                                    size: 16,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onChanged:
                                      (
                                        int? newYear,
                                      ) {
                                        if (newYear !=
                                            null) {
                                          controller.updateFocusedYear(
                                            newYear,
                                          );
                                          onStateChanged();
                                        }
                                      },
                                  items:
                                      List.generate(
                                        6,
                                        (
                                          index,
                                        ) =>
                                            2026 +
                                            index,
                                      ).map(
                                        (
                                          int year,
                                        ) {
                                          return DropdownMenuItem<
                                            int
                                          >(
                                            value: year,
                                            child: Text(
                                              "$year",
                                            ),
                                          );
                                        },
                                      ).toList(),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Icon(
                        controller.isCalendarExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white38,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.isCalendarExpanded)
                Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white60,
                        size: 20,
                      ),
                      onPressed: () {
                        controller.navigateMonth(
                          forward: false,
                        );
                        onStateChanged();
                      },
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white60,
                        size: 20,
                      ),
                      onPressed: () {
                        controller.navigateMonth(
                          forward: true,
                        );
                        onStateChanged();
                      },
                    ),
                  ],
                )
              else if (filteredAppointments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: controller.calendarPurpleAccent.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(
                      6,
                    ),
                  ),
                  child: Text(
                    "${filteredAppointments.length} Tasks",
                    style: TextStyle(
                      color: controller.calendarPurpleAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (controller.isCalendarExpanded) ...[
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  [
                        "D",
                        "S",
                        "T",
                        "Q",
                        "Q",
                        "S",
                        "S",
                      ]
                      .map(
                        (
                          d,
                        ) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(
              height: 6,
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.0,
              ),
              itemCount:
                  daysInMonth +
                  firstDayOffset,
              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    if (index <
                        firstDayOffset)
                      return const SizedBox.shrink();
                    final int day =
                        index -
                        firstDayOffset +
                        1;
                    final bool isSelected =
                        day ==
                        controller.selectedDay;

                    final bool hasAppointment = controller.appointments.any(
                      (
                        element,
                      ) =>
                          element['day'] ==
                              day &&
                          element['month'] ==
                              controller.focusedDay.month &&
                          element['year'] ==
                              controller.focusedDay.year,
                    );

                    return GestureDetector(
                      onTap: () {
                        controller.selectDay(
                          day,
                        );
                        onStateChanged();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? controller.calendarPurpleAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            6,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              "$day",
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.white24,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (hasAppointment &&
                                !isSelected)
                              Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: controller.calendarPurpleAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
            ),
          ],
          const SizedBox(
            height: 10,
          ),
          ...filteredAppointments.map(
            (
              app,
            ) => Container(
              margin: const EdgeInsets.symmetric(
                vertical: 4,
              ),
              padding: const EdgeInsets.all(
                10,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.24,
                ),
                borderRadius: BorderRadius.circular(
                  8,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    app['time'],
                    style: TextStyle(
                      color: controller.calendarPurpleAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      app['title'],
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: controller.calendarPurpleAccent.withValues(
                    alpha: 0.4,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    8,
                  ),
                ),
              ),
              onPressed: onAddAppointmentTap,
              icon: Icon(
                Icons.add,
                color: controller.calendarPurpleAccent,
                size: 14,
              ),
              label: Text(
                "ADD TASK",
                style: TextStyle(
                  color: controller.calendarPurpleAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
