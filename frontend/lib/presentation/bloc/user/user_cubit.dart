import 'package:bloc/bloc.dart';
import 'package:frontend/data/models/user.dart';

class UserCubit extends Cubit<User> {
  UserCubit() : super(User(id: '')); 
  void update(User n) => emit(n); 
}