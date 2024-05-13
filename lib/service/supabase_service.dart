import 'dart:convert';
import 'dart:developer';

import 'package:due_kasir/model/customer_model.dart';
import 'package:due_kasir/model/expenses_model.dart';
import 'package:due_kasir/model/item_model.dart';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/presence_model.dart';
import 'package:due_kasir/model/rent_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/rent_model.dart';

class SupabaseHelper {
  static final SupabaseClient supabase = Supabase.instance.client;

  Future getInventoryAll() async {
    List data = [];
    List<ItemModel> allInventory = [];

    final result = await supabase
        .from('inventory')
        .select()
        .eq('user', supabase.auth.currentUser!.id);
    if (result.isNotEmpty) {
      await Future.forEach(result, (val) async => data.add(val));
    }
    await Future.forEach(data, (val) async {
      allInventory.add(ItemModel.fromJson(val));
    });

    return allInventory;
  }

  addInventory(Map data) async {
    data.putIfAbsent('user', () => supabase.auth.currentUser!.id);
    await supabase.from('inventory').insert(data).then((value) {
      log('success add inventory $value');
    }).catchError((error) {
      log('error add inventory $error');
    });
  }

  removeInventory(int id) async {
    await supabase.from('inventory').select().eq("id", id).then((value) async {
      await supabase.from('inventory').delete().eq('id', id);
    });
  }

  updateInventory(ItemModel item) async {
    await supabase
        .from('inventory')
        .select()
        .eq("id", item.id!)
        .then((value) async {
      if (value.isEmpty) {
        addInventory(item.toJson());
      } else {
        await supabase
            .from('inventory')
            .update(item.toJson())
            .match({'id': item.id!});
      }
    });
  }

  // customer
  Future getCustomerAll() async {
    List<CustomerModel> allCustomer = [];

    await supabase
        .from('customer')
        .select()
        .eq('user', supabase.auth.currentUser!.id)
        .then(
      (val) {
        for (var element in val) {
          allCustomer.add(CustomerModel.fromJson(element));
        }
      },
    );

    return allCustomer;
  }

  addCustomer(Map data) async {
    data.putIfAbsent('user', () => supabase.auth.currentUser!.id);
    await supabase.from('customer').insert(data).then((value) {
      log('success add customer $value');
    }).catchError((error) {
      log('error add customer $error');
    });
  }

  removeCustomer(int id) async {
    await supabase.from('customer').select().eq("id", id).then((value) async {
      await supabase.from('customer').delete().eq('id', id);
    });
  }

  Future<bool> getCustomerById(int id) async {
    final res = await supabase.from('customer').select().eq("id", id);
    return res.isNotEmpty;
  }

  updateCustomer(CustomerModel item) async {
    await supabase
        .from('customer')
        .select()
        .eq("id", item.id!)
        .then((value) async {
      if (value.isEmpty) {
        addInventory(item.toJson());
      } else {
        await supabase
            .from('customer')
            .update(item.toJson())
            .match({'id': item.id!});
      }
    });
  }

  Future getRepots() async {
    List<PenjualanModel> allReport = [];

    final result = await supabase
        .from('report')
        .select()
        .eq('user', supabase.auth.currentUser!.id);

    if (result.isNotEmpty) {
      await Future.forEach(result, (val) async {
        final List<dynamic> convertItem = jsonDecode(val['items']);
        List<ProductItemModel> listProduct = [];
        await Future.forEach(convertItem, (p) async {
          listProduct.add(ProductItemModel.fromJson(p));
        });

        allReport.add(
          PenjualanModel(
            id: val['id'],
            pembeli: val['pembeli'],
            diskon: val['diskon'].toDouble(),
            kasir: val['kasir'],
            keterangan: val['keterangan'],
            totalItem: val['totalItem'],
            totalHarga: val['totalHarga'].toDouble(),
            createdAt: DateTime.parse(val['createdAt']),
            items: listProduct,
          ),
        );
      });
    }

    return allReport;
  }

  addReport(Map data) async {
    data.putIfAbsent('user', () => supabase.auth.currentUser!.id);
    await supabase.from('report').insert(data).then((value) {
      log('success add inventory $value');
    }).catchError((error) {
      log('error add inventory $error');
    });
  }

  Future<bool> getReportById(int id) async {
    final res = await supabase.from('report').select().eq("id", id);
    return res.isNotEmpty;
  }

  removeReport(int id) async {
    await supabase.from('report').select().eq("id", id).then((value) async {
      await supabase.from('report').delete().eq('id', id);
    });
  }

  updateReport(PenjualanModel item) async {
    await supabase
        .from('report')
        .select()
        .eq("id", item.id!)
        .then((value) async {
      if (value.isEmpty) {
        addInventory(item.toJson());
      } else {
        await supabase
            .from('report')
            .update(item.toJson())
            .match({'id': item.id!});
      }
    });
  }

  // presense
  addPresense(Map data) async {
    data.putIfAbsent('belong', () => supabase.auth.currentUser!.id);
    await supabase.from('presense').insert(data).then((value) {
      log('success add presense $value');
    }).catchError((error) {
      log('error add presense $error');
    });
  }

  Future getPresense() async {
    List<PresenceModel> allPresense = [];

    final result = await supabase
        .from('presense')
        .select()
        .eq('belong', supabase.auth.currentUser!.id);

    if (result.isNotEmpty) {
      await Future.forEach(result, (val) async {
        allPresense.add(PresenceModel.fromJson(val));
      });
    }
    return allPresense;
  }

  // rent item
  addRentItem(Map data) async {
    data.putIfAbsent('user', () => supabase.auth.currentUser!.id);
    await supabase.from('rent_items').insert(data).then((value) {
      log('success add presense $value');
    }).catchError((error) {
      log('error add presense $error');
    });
  }

  Future getRentItems() async {
    List<RentItemModel> rentItems = [];

    final result = await supabase
        .from('rent_items')
        .select()
        .eq('user', supabase.auth.currentUser!.id);

    if (result.isNotEmpty) {
      await Future.forEach(result, (val) async {
        rentItems.add(RentItemModel.fromJson(val));
      });
    }
    return rentItems;
  }

  removeRentItem(int id) async {
    await supabase.from('rent_items').select().eq("id", id).then((value) async {
      await supabase.from('rent_items').delete().eq('id', id);
    });
  }

  updateRentItem(RentItemModel item) async {
    await supabase
        .from('rent_items')
        .select()
        .eq("id", item.id!)
        .then((value) async {
      if (value.isEmpty) {
        addRentItem(item.toJson());
      } else {
        await supabase
            .from('rent_items')
            .update(item.toJson())
            .match({'id': item.id!});
      }
    });
  }

  // rent
  addRent(Map data) async {
    data.putIfAbsent('user', () => supabase.auth.currentUser!.id);
    await supabase.from('rent').insert(data).then((value) {
      log('success add presense $value');
    }).catchError((error) {
      log('error add presense $error');
    });
  }

  Future getRent() async {
    List<RentModel> rentItems = [];

    final result = await supabase
        .from('rent')
        .select()
        .eq('user', supabase.auth.currentUser!.id);

    if (result.isNotEmpty) {
      await Future.forEach(result, (val) async {
        rentItems.add(RentModel.fromJson(val));
      });
    }
    return rentItems;
  }

  updateRent(RentModel item) async {
    await supabase.from('rent').select().eq("id", item.id!).then((value) async {
      if (value.isEmpty) {
        addRent(item.toJson());
      } else {
        await supabase
            .from('rent')
            .update(item.toJson())
            .match({'id': item.id!});
      }
    });
  }

  // expenses
  addExpenses(Map data) async {
    data.putIfAbsent('user', () => supabase.auth.currentUser!.id);
    await supabase.from('expenses').insert(data).then((value) {
      log('success add presense $value');
    }).catchError((error) {
      log('error add presense $error');
    });
  }

  Future getExpenses() async {
    List<ExpensesModel> expensesItems = [];

    final result = await supabase
        .from('expenses')
        .select()
        .eq('user', supabase.auth.currentUser!.id);

    if (result.isNotEmpty) {
      await Future.forEach(result, (val) async {
        expensesItems.add(ExpensesModel.fromJson(val));
      });
    }
    return expensesItems;
  }
}
