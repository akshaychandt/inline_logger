import 'package:flutter/material.dart';
import 'package:inline_logger/inline_logger.dart';

void main() {
  // Configure logger for development
  LoggerConfig.showTimestamp = true;
  LoggerConfig.showEmoji = true;
  LoggerConfig.minLevel = LogLevel.debug;
  LoggerConfig.useColors = true; // Enable colored console output

  Logger.info('App starting', 'main');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'inline_logger Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  int _counter = 0;
  List<String> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Logger.lifecycle('initState', 'ExampleHomePage initialized');
  }

  void _incrementCounter() {
    Logger.header('INCREMENT COUNTER');

    setState(() {
      _counter = (_counter + 1).logSuccess('New counter value');
    });

    Logger.divider();
  }

  Future<void> _simulateApiCall() async {
    Logger.header('SIMULATE API CALL');

    setState(() {
      _isLoading = true;
      Logger.state('isLoading', _isLoading);
    });

    Logger.apiRequest(
      endpoint: '/api/items',
      method: 'GET',
    );

    // Simulate network delay
    final stopwatch = Stopwatch()..start();
    await Future.delayed(const Duration(seconds: 2));
    stopwatch.stop();

    final mockData = ['Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5'];

    Logger.apiResponse(
      endpoint: '/api/items',
      statusCode: 200,
      data: mockData,
      duration: stopwatch.elapsed,
    );

    setState(() {
      _items = mockData.logSuccess('Items loaded');
      _isLoading = false;
      Logger.state('isLoading', _isLoading);
    });

    Logger.divider();
  }

  void _demonstrateLogLevels() {
    Logger.header('LOG LEVELS DEMO');

    Logger.debug('This is a debug message');
    Logger.verbose('This is a verbose message');
    Logger.info('This is an info message');
    Logger.success('This is a success message');
    Logger.warning('This is a warning message');
    Logger.error('This is an error message');
    Logger.critical('This is a critical message');

    Logger.divider();
  }

  void _demonstrateInlineLogging() {
    Logger.header('INLINE LOGGING DEMO');

    // Example 1: Simple inline logging
    'John Doe'.log('User name');

    // Example 2: Chained logging
    [1, 2, 3, 4, 5]
        .log('Initial list')
        .map((e) => e * 2)
        .toList()
        .logInfo('Doubled list')
        .where((e) => e > 5)
        .toList()
        .logSuccess('Filtered list');

    // Example 3: Different log levels
    const age = 25;
    age.logDebug('User age');
    age.logVerbose('User age verbose');
    age.logInfo('User age info');
    age.logSuccess('User age success');
    age.logWarning('User age warning');

    Logger.divider();

    // Show snackbar to confirm
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check console for inline logging examples!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLogHistory() {
    Logger.header('LOG HISTORY');

    final history = LoggerConfig.logHistory;
    Logger.info('Total logs in history: ${history.length}');

    for (var log in history) {
      Logger.verbose(log);
    }

    Logger.divider();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Log History'),
          content: Text(
            history.isEmpty
                ? 'No logs in history yet.\n\n'
                    'Try triggering errors or warnings!'
                : 'Found ${history.length} logs.\n\n'
                    'Check console for details.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                LoggerConfig.clearHistory();
                Logger.success('History cleared');
                Navigator.pop(context);
              },
              child: const Text('Clear History'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('inline_logger Example').log('AppBar title'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Counter Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Counter Example',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Count: ${_counter.log('Current counter')}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _incrementCounter,
                      icon: const Icon(Icons.add),
                      label: const Text('Increment'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // API Call Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'API Call Example',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else if (_items.isEmpty)
                      const Text('No items loaded yet')
                    else
                      Column(
                        children: _items
                            .map((item) => ListTile(
                                  leading: const Icon(Icons.check_circle),
                                  title: Text(item.log('List item')),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _simulateApiCall,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Fetch Items'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logging Examples
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Logging Examples',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _demonstrateLogLevels,
                      icon: const Icon(Icons.format_list_bulleted),
                      label: const Text('Show All Log Levels'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _demonstrateInlineLogging,
                      icon: const Icon(Icons.link),
                      label: const Text('Inline Logging Demo'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showLogHistory,
                      icon: const Icon(Icons.history),
                      label: const Text('View Log History'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Open your console to see logs!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All logging is visible in your IDE console '
                      'or terminal. Try clicking the buttons above to see '
                      'different logging features in action.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    Logger.lifecycle('dispose', 'ExampleHomePage disposed');
    super.dispose();
  }
}
