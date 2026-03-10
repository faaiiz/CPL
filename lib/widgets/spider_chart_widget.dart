import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SpiderChartWidget extends StatefulWidget {
  final Map<String, double> dataPoints; // Label -> Value (0-100)
  final String title;
  final Color chartColor;

  const SpiderChartWidget({
    super.key,
    required this.dataPoints,
    required this.title,
    this.chartColor = const Color(0xFFFF69B4),
  });

  @override
  State<SpiderChartWidget> createState() => _SpiderChartWidgetState();
}

class _SpiderChartWidgetState extends State<SpiderChartWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Prepare data for radar chart
    final labels = widget.dataPoints.keys.toList();
    final values = widget.dataPoints.values.toList();

    if (labels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    // Determine chart size based on expansion state
    final chartSize = _isExpanded ? 700.0 : 550.0;
    
    if (_isExpanded) {
      // Fullscreen expanded mode
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: widget.chartColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isExpanded = false;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: chartSize,
                        width: chartSize,
                        child: _buildRadarChart(labels, values, widget.chartColor),
                      ),
                      const SizedBox(height: 32),
                      _buildLegend(widget.chartColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Default collapsed mode
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expand button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(
                    Icons.fullscreen,
                    color: widget.chartColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = true;
                    });
                    showDialog(
                      context: context,
                      builder: (context) => _buildExpandedDialog(labels, values),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Chart Section
              Center(
                child: SizedBox(
                  height: chartSize,
                  width: chartSize,
                  child: _buildRadarChart(labels, values, widget.chartColor),
                ),
              ),
              const SizedBox(height: 10),
              // Footer Legend
              _buildLegend(widget.chartColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarChart(List<String> labels, List<double> values, Color chartColor) {
    // 🎯 FIX: Gunakan 2 dataset:
    // 1. Data asli - visible dengan warna chartColor
    // 2. Dataset "ghost" dengan semua values=100 - transparent (untuk force scale 0-100)
    
    final actualEntries = values
        .map((value) => RadarEntry(value: value.clamp(0, 100)))
        .toList();
    
    // Ghost dataset dengan values 100 untuk semua labels - akan force scale tanpa terlihat
    final ghostEntries = List<RadarEntry>.filled(
      labels.length,
      const RadarEntry(value: 100),
    );

    return RadarChart(
      RadarChartData(
        dataSets: [
          // Dataset asli - visible dengan chartColor
          RadarDataSet(
            borderColor: chartColor,
            fillColor: chartColor.withOpacity(0.25),
            dataEntries: actualEntries,
            borderWidth: 3,
          ),
          // Dataset "ghost" - transparent, invisible, hanya untuk force scale ke 100
          RadarDataSet(
            borderColor: Colors.transparent,
            fillColor: Colors.transparent,
            dataEntries: ghostEntries,
            borderWidth: 0,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        gridBorderData: BorderSide(
          color: chartColor.withOpacity(0.15),
          width: 1.2,
        ),
        // Skala fixed dari 0 - 100 dengan interval 10 (10 ticks)
        tickCount: 10,
        tickBorderData: BorderSide(
          color: chartColor.withOpacity(0.25),
          width: 1.5,
        ),
        ticksTextStyle: TextStyle(
          color: chartColor.withOpacity(0.7),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        radarTouchData: RadarTouchData(
          enabled: true,
          touchSpotThreshold: 10,
        ),
        getTitle: (index, angle) {
          if (index < labels.length) {
            return RadarChartTitle(
              text: labels[index],
              angle: angle,
              positionPercentageOffset: 0.15,
            );
          }
          return RadarChartTitle(text: '');
        },
        titlePositionPercentageOffset: 0.2,
      ),
    );
  }

  Widget _buildLegend(Color chartColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: chartColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: chartColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Nilai Capaian: 0-100',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDialog(List<String> labels, List<double> values) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: widget.chartColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isExpanded = false;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 700,
                      width: 700,
                      child: _buildRadarChart(labels, values, widget.chartColor),
                    ),
                    const SizedBox(height: 32),
                    _buildLegend(widget.chartColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
