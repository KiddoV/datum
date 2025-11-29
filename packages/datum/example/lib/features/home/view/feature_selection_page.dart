import 'package:auto_route/auto_route.dart';
import 'package:example/core/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

@RoutePage()
class FeatureSelectionPage extends StatelessWidget {
  const FeatureSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Selection'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            ResponsiveValue<double>(
              context,
              conditionalValues: [
                const Condition.equals(name: MOBILE, value: 16),
                const Condition.equals(name: TABLET, value: 24),
                const Condition.equals(name: DESKTOP, value: 32),
                const Condition.equals(name: '4K', value: 48),
              ],
              defaultValue: 20,
            ).value,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Choose a Feature to Test',
                style: TextStyle(
                  fontSize: ResponsiveValue<double>(
                    context,
                    conditionalValues: [
                      const Condition.equals(name: MOBILE, value: 20),
                      const Condition.equals(name: TABLET, value: 24),
                      const Condition.equals(name: DESKTOP, value: 32),
                      const Condition.equals(name: '4K', value: 40),
                    ],
                    defaultValue: 24,
                  ).value,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(
                height: ResponsiveValue<double>(
                  context,
                  conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 32),
                    const Condition.equals(name: TABLET, value: 40),
                    const Condition.equals(name: DESKTOP, value: 48),
                    const Condition.equals(name: '4K', value: 64),
                  ],
                  defaultValue: 40,
                ).value,
              ),
              SizedBox(
                width: ResponsiveValue<double>(
                  context,
                  conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 220),
                    const Condition.equals(name: TABLET, value: 260),
                    const Condition.equals(name: DESKTOP, value: 320),
                    const Condition.equals(name: '4K', value: 400),
                  ],
                  defaultValue: 250,
                ).value,
                height: ResponsiveValue<double>(
                  context,
                  conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 50),
                    const Condition.equals(name: TABLET, value: 60),
                    const Condition.equals(name: DESKTOP, value: 70),
                    const Condition.equals(name: '4K', value: 80),
                  ],
                  defaultValue: 60,
                ).value,
                child: ElevatedButton(
                  onPressed: () {
                    AutoRouter.of(context).push(const SimpleDatumRoute());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: ResponsiveValue<double>(
                          context,
                          conditionalValues: [
                            const Condition.equals(name: MOBILE, value: 20),
                            const Condition.equals(name: TABLET, value: 24),
                            const Condition.equals(name: DESKTOP, value: 28),
                            const Condition.equals(name: '4K', value: 32),
                          ],
                          defaultValue: 24,
                        ).value,
                      ),
                      SizedBox(
                        width: ResponsiveValue<double>(
                          context,
                          conditionalValues: [
                            const Condition.equals(name: MOBILE, value: 8),
                            const Condition.equals(name: TABLET, value: 12),
                            const Condition.equals(name: DESKTOP, value: 16),
                            const Condition.equals(name: '4K', value: 20),
                          ],
                          defaultValue: 12,
                        ).value,
                      ),
                      Text(
                        'Simple Datum',
                        style: TextStyle(
                          fontSize: ResponsiveValue<double>(
                            context,
                            conditionalValues: [
                              const Condition.equals(name: MOBILE, value: 14),
                              const Condition.equals(name: TABLET, value: 16),
                              const Condition.equals(name: DESKTOP, value: 20),
                              const Condition.equals(name: '4K', value: 24),
                            ],
                            defaultValue: 18,
                          ).value,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: ResponsiveValue<double>(
                  context,
                  conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 16),
                    const Condition.equals(name: TABLET, value: 20),
                    const Condition.equals(name: DESKTOP, value: 24),
                    const Condition.equals(name: '4K', value: 32),
                  ],
                  defaultValue: 20,
                ).value,
              ),
              SizedBox(
                width: ResponsiveValue<double>(
                  context,
                  conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 220),
                    const Condition.equals(name: TABLET, value: 260),
                    const Condition.equals(name: DESKTOP, value: 320),
                    const Condition.equals(name: '4K', value: 400),
                  ],
                  defaultValue: 250,
                ).value,
                height: ResponsiveValue<double>(
                  context,
                  conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 50),
                    const Condition.equals(name: TABLET, value: 60),
                    const Condition.equals(name: DESKTOP, value: 70),
                    const Condition.equals(name: '4K', value: 80),
                  ],
                  defaultValue: 60,
                ).value,
                child: ElevatedButton(
                  onPressed: () {
                    AutoRouter.of(context).push(const PaintRoute());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.brush,
                        size: ResponsiveValue<double>(
                          context,
                          conditionalValues: [
                            const Condition.equals(name: MOBILE, value: 20),
                            const Condition.equals(name: TABLET, value: 24),
                            const Condition.equals(name: DESKTOP, value: 28),
                            const Condition.equals(name: '4K', value: 32),
                          ],
                          defaultValue: 24,
                        ).value,
                      ),
                      SizedBox(
                        width: ResponsiveValue<double>(
                          context,
                          conditionalValues: [
                            const Condition.equals(name: MOBILE, value: 8),
                            const Condition.equals(name: TABLET, value: 12),
                            const Condition.equals(name: DESKTOP, value: 16),
                            const Condition.equals(name: '4K', value: 20),
                          ],
                          defaultValue: 12,
                        ).value,
                      ),
                      Text(
                        'Paint Canvas',
                        style: TextStyle(
                          fontSize: ResponsiveValue<double>(
                            context,
                            conditionalValues: [
                              const Condition.equals(name: MOBILE, value: 14),
                              const Condition.equals(name: TABLET, value: 16),
                              const Condition.equals(name: DESKTOP, value: 20),
                              const Condition.equals(name: '4K', value: 24),
                            ],
                            defaultValue: 18,
                          ).value,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: ResponsiveValue<double>(
                  context,
                  conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 32),
                    const Condition.equals(name: TABLET, value: 40),
                    const Condition.equals(name: DESKTOP, value: 48),
                    const Condition.equals(name: '4K', value: 64),
                  ],
                  defaultValue: 40,
                ).value,
              ),
              Container(
                padding: EdgeInsets.all(
                  ResponsiveValue<double>(
                    context,
                    conditionalValues: [
                      const Condition.equals(name: MOBILE, value: 16),
                      const Condition.equals(name: TABLET, value: 20),
                      const Condition.equals(name: DESKTOP, value: 24),
                      const Condition.equals(name: '4K', value: 32),
                    ],
                    defaultValue: 20,
                  ).value,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveValue<double>(
                    context,
                    conditionalValues: [
                      const Condition.equals(name: MOBILE, value: 16),
                      const Condition.equals(name: TABLET, value: 24),
                      const Condition.equals(name: DESKTOP, value: 32),
                      const Condition.equals(name: '4K', value: 48),
                    ],
                    defaultValue: 20,
                  ).value,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Features to Test:',
                      style: TextStyle(
                        fontSize: ResponsiveValue<double>(
                          context,
                          conditionalValues: [
                            const Condition.equals(name: MOBILE, value: 14),
                            const Condition.equals(name: TABLET, value: 16),
                            const Condition.equals(name: DESKTOP, value: 18),
                            const Condition.equals(name: '4K', value: 22),
                          ],
                          defaultValue: 16,
                        ).value,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveValue<double>(
                        context,
                        conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 8),
                          const Condition.equals(name: TABLET, value: 12),
                          const Condition.equals(name: DESKTOP, value: 16),
                          const Condition.equals(name: '4K', value: 20),
                        ],
                        defaultValue: 12,
                      ).value,
                    ),
                    Text(
                      '• Simple Datum: Task management with real-time sync\n• Paint Canvas: Drawing with undo/redo and real-time sync',
                      style: TextStyle(
                        fontSize: ResponsiveValue<double>(
                          context,
                          conditionalValues: [
                            const Condition.equals(name: MOBILE, value: 12),
                            const Condition.equals(name: TABLET, value: 14),
                            const Condition.equals(name: DESKTOP, value: 16),
                            const Condition.equals(name: '4K', value: 20),
                          ],
                          defaultValue: 14,
                        ).value,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
