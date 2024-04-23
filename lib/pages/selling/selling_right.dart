import 'dart:async';
import 'dart:io';

import 'package:due_kasir/controller/selling/events.dart';
import 'package:due_kasir/controller/selling_controller.dart';
import 'package:due_kasir/controller/store_controller.dart';
import 'package:due_kasir/enum/payment_enum.dart';
import 'package:due_kasir/model/item_model.dart';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/printer_model.dart';
import 'package:due_kasir/model/store_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:due_kasir/service/get_it.dart';
import 'package:due_kasir/utils/constant.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

class SellingRight extends StatefulHookConsumerWidget {
  const SellingRight({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SellingRightState();
}

class _SellingRightState extends ConsumerState<SellingRight> {
  final _sellingFormKey = GlobalKey<FormState>();
  StreamSubscription<BTStatus>? _subscriptionBtStatus;
  StreamSubscription<USBStatus>? _subscriptionUsbStatus;
  var _isConnected = false;

  BTStatus _currentStatus = BTStatus.none;
  // ignore: unused_field
  USBStatus _currentUsbStatus = USBStatus.none;
  List<int>? pendingTask;

  @override
  void initState() {
    super.initState();
    // subscription to listen change status of bluetooth connection
    _subscriptionBtStatus =
        PrinterManager.instance.stateBluetooth.listen((status) {
      _currentStatus = status;
      if (status == BTStatus.connected) {
        setState(() => _isConnected = true);
      }
      if (status == BTStatus.none) {
        setState(() => _isConnected = false);
      }
      if (status == BTStatus.connected && pendingTask != null) {
        if (Platform.isAndroid) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            PrinterManager.instance
                .send(type: PrinterType.bluetooth, bytes: pendingTask!);
            pendingTask = null;
          });
        } else if (Platform.isIOS) {
          PrinterManager.instance
              .send(type: PrinterType.bluetooth, bytes: pendingTask!);
          pendingTask = null;
        }
      }
    });
    //  PrinterManager.instance.stateUSB is only supports on Android
    _subscriptionUsbStatus = PrinterManager.instance.stateUSB.listen((status) {
      _currentUsbStatus = status;
      if (Platform.isAndroid) {
        if (status == USBStatus.connected && pendingTask != null) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            PrinterManager.instance
                .send(type: PrinterType.usb, bytes: pendingTask!);
            pendingTask = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscriptionBtStatus?.cancel();
    _subscriptionUsbStatus?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final print = getIt.get<SellingController>().selectedPrint.watch(context);
    final store = storeController.store.watch(context);
    final tipeBayar = getIt.get<SellingController>().tipeBayar.watch(context);
    final pelanggan = getIt.get<SellingController>().pelanggan.watch(context);
    final kasir = getIt.get<SellingController>().kasir.watch(context);
    final list = getIt.get<SellingController>().cart.watch(context);
    final cashEditing = useTextEditingController(text: '0');
    final note = useTextEditingController();

    useListenable(cashEditing);
    useListenable(note);
    return SingleChildScrollView(
      child: Form(
        key: _sellingFormKey,
        child: ShadCard(
          title: Text('Payment', style: ShadTheme.of(context).textTheme.h4),
          description: Text('Rangkuman belanja ${store.value?.title ?? ''}'),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(kasir?.nama ?? 'Admin'),
                  subtitle: const Text('Kasir'),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () => context.push('/home'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(pelanggan?.nama ?? 'Mommy'),
                  subtitle: const Text('Pelanggan'),
                  trailing: const Icon(Icons.arrow_right),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Total'),
                  trailing: Text(
                    currency.format(list.value?.totalPrice ?? 0),
                    style: ShadTheme.of(context).textTheme.large,
                  ),
                ),
                ShadRadioGroupFormField<TypePayment>(
                  label: const Text('Tipe pembayaran'),
                  initialValue: tipeBayar,
                  onChanged: (TypePayment? val) {
                    getIt.get<SellingController>().tipeBayar.value = val!;
                  },
                  items: TypePayment.values.map(
                    (e) => ShadRadio(
                      value: e,
                      label: Text(e.message),
                    ),
                  ),
                  validator: (v) {
                    if (v == null) {
                      return 'You need to select a notification type.';
                    }
                    return null;
                  },
                ),
                if (tipeBayar == TypePayment.cash)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nominal Cash'),
                            ShadInput(
                              controller: cashEditing,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kembalian'),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(currency.format((double.parse(
                                    cashEditing.text.isNotEmpty
                                        ? cashEditing.text
                                        : '0') -
                                (list.value?.totalPrice ?? 0.0)))),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ))
                    ],
                  ),
                const Text('Catatan'),
                ShadInput(
                  controller: note,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          footer: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ShadCheckboxFormField(
                  id: 'terms',
                  initialValue: false,
                  inputLabel: const Text('Saya Bertanggun Jawab'),
                  onChanged: (v) {},
                  inputSublabel: const Text(
                      'Barang sudah saya cek dan sudah di bayar pelanggan dengan nominal yg benar'),
                  validator: (v) {
                    if (!v) {
                      return 'You must accept the terms and conditions';
                    }
                    return null;
                  },
                ),
              ),
              ShadButton(
                onPressed: () {
                  if (_sellingFormKey.currentState!.validate() &&
                      store.hasValue &&
                      print != null) {
                    final newItem = PenjualanModel()
                      ..items.addAll(list.value!.items)
                      ..kasir = kasir?.id ?? 1
                      ..keterangan = note.text
                      ..diskon = 0
                      ..totalHarga = list.value?.totalPrice ?? 0.0
                      ..totalItem = list.value?.totalItem ?? 0
                      ..pembeli = pelanggan?.id;
                    Database().addPenjualan(newItem).whenComplete(() {
                      letsPrint(
                        store: store.value!,
                        print: print,
                        model: newItem,
                        kasir: kasir?.nama ?? 'Umum',
                        tipe: tipeBayar,
                        cash: cashEditing.text,
                        kembalian: (double.parse(cashEditing.text.isNotEmpty
                                    ? cashEditing.text
                                    : '0') -
                                (list.value?.totalPrice ?? 0.0))
                            .toString(),
                      ).whenComplete(() {
                        cashEditing.clear();
                        note.clear();
                        getIt.get<SellingController>().tipeBayar.value =
                            TypePayment.qris;
                        getIt
                            .get<SellingController>()
                            .updateBatch(list.value!.items)
                            .whenComplete(() => getIt
                                .get<SellingController>()
                                .dispatch(CartPaid()));
                      });
                    });
                  }
                },
                text: const Text('Print'),
                icon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    _isConnected ? Icons.print : Icons.print_disabled,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> letsPrint({
    required StoreModel store,
    required PrinterModel print,
    required PenjualanModel model,
    required String kasir,
    required TypePayment tipe,
    String? cash,
    String? kembalian,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];
    // Print image:
    // final ByteData data =
    //     await rootBundle.load('assets/logo.png');
    // final Uint8List imgBytes = data.buffer.asUint8List();
    // final image = imgs.decodeImage(imgBytes)!;
    // bytes += generator.image(image);
    // Print image using an alternative (obsolette) command
    // bytes += generator.imageRaster(image);
    bytes += generator.text(store.title,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));
    bytes += generator.feed(1);
    bytes += generator.text(store.description,
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(store.phone,
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
        text: '${DateTime.now()}',
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: kasir,
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.hr();
    for (ItemModel i in model.items) {
      bytes += generator.text(i.nama);
      bytes += generator.row([
        PosColumn(
          text: '${i.quantity} x ${i.hargaJual}',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '${i.quantity * i.hargaJual}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
        text: 'Total',
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: model.totalHarga.toString(),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'Bayar',
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: tipe == TypePayment.cash ? cash! : tipe.name,
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    if (tipe == TypePayment.cash) {
      bytes += generator.row([
        PosColumn(
          text: 'Kembali',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: kembalian ?? '0',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.feed(2);
    if (store.footer != null) {
      bytes += generator.text(store.footer!,
          styles: const PosStyles(align: PosAlign.center));
    }
    if (store.subFooter != null) {
      bytes += generator.text(store.subFooter!,
          styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.feed(2);
    bytes += generator.cut();
    bytes += generator.drawer();
    // await _flutterThermalPrinterPlugin.send(
    //   print,
    //   bytes,
    // );
    var bluetoothPrinter = print;

    switch (bluetoothPrinter.typePrinter) {
      case PrinterType.usb:
        bytes += generator.feed(2);
        bytes += generator.cut();
        await PrinterManager.instance.connect(
            type: bluetoothPrinter.typePrinter,
            model: UsbPrinterInput(
                name: bluetoothPrinter.deviceName,
                productId: bluetoothPrinter.productId,
                vendorId: bluetoothPrinter.vendorId));
        pendingTask = null;
        break;
      case PrinterType.bluetooth:
        bytes += generator.cut();
        await PrinterManager.instance.connect(
            type: bluetoothPrinter.typePrinter,
            model: BluetoothPrinterInput(
                name: bluetoothPrinter.deviceName,
                address: bluetoothPrinter.address!,
                isBle: bluetoothPrinter.isBle ?? false,
                autoConnect: true));
        pendingTask = null;
        if (Platform.isAndroid) pendingTask = bytes;
        break;

      default:
    }
    if (bluetoothPrinter.typePrinter == PrinterType.bluetooth &&
        Platform.isAndroid) {
      if (_currentStatus == BTStatus.connected) {
        PrinterManager.instance
            .send(type: bluetoothPrinter.typePrinter, bytes: bytes);
        pendingTask = null;
      }
    } else {
      PrinterManager.instance
          .send(type: bluetoothPrinter.typePrinter, bytes: bytes);
    }
  }
}
