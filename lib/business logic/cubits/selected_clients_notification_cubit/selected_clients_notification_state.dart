import 'package:equatable/equatable.dart';
import 'package:goods_admin/business%20logic/cubits/selected_clients_notification_cubit/selected_clients_notification_cubit.dart';
import 'package:goods_admin/data/models/client_model.dart';

abstract class SelectedClientsState extends Equatable {
  const SelectedClientsState();

  @override
  List<Object?> get props => [];
}

class SelectedClientsInitial extends SelectedClientsState {}

class SelectedClientsLoading extends SelectedClientsState {}

class SelectedClientsLoaded extends SelectedClientsState {
  final List<ClientModel> clients;
  final List<ClientModel> filteredClients;
  final String searchQuery;
  final ClientFilter currentFilter;
  final int selectedCount;
  final Map<String, int> categoryCounts;
  final Map<String, int> governmentCounts;

  const SelectedClientsLoaded({
    required this.clients,
    required this.filteredClients,
    this.searchQuery = '',
    this.currentFilter = ClientFilter.all,
    this.selectedCount = 0,
    this.categoryCounts = const {},
    this.governmentCounts = const {},
  });

  SelectedClientsLoaded copyWith({
    List<ClientModel>? clients,
    List<ClientModel>? filteredClients,
    String? searchQuery,
    ClientFilter? currentFilter,
    int? selectedCount,
    Map<String, int>? categoryCounts,
    Map<String, int>? governmentCounts,
  }) {
    return SelectedClientsLoaded(
      clients: clients ?? this.clients,
      filteredClients: filteredClients ?? this.filteredClients,
      searchQuery: searchQuery ?? this.searchQuery,
      currentFilter: currentFilter ?? this.currentFilter,
      selectedCount: selectedCount ?? this.selectedCount,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      governmentCounts: governmentCounts ?? this.governmentCounts,
    );
  }

  @override
  List<Object?> get props => [
        clients,
        filteredClients,
        searchQuery,
        currentFilter,
        selectedCount,
        categoryCounts,
        governmentCounts,
      ];
}

class SelectedClientsError extends SelectedClientsState {
  final String message;

  const SelectedClientsError(this.message);

  @override
  List<Object> get props => [message];
}

class SelectedClientsSending extends SelectedClientsState {
  final String message;
  final bool isUploadingImage;

  const SelectedClientsSending({
    required this.message,
    this.isUploadingImage = false,
  });

  @override
  List<Object> get props => [message, isUploadingImage];
}

class SelectedClientsSent extends SelectedClientsState {
  final String message;
  final int successCount;
  final int totalClients;

  const SelectedClientsSent({
    required this.message,
    required this.successCount,
    required this.totalClients,
  });

  @override
  List<Object> get props => [message, successCount, totalClients];
}
