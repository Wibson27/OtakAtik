import 'package:bloc/bloc.dart';
import 'package:frontend/data/models/user.dart';

class UserCubit extends Cubit<User> {
  UserCubit() : super(User(id: '')); 

  void update(User newUser) => emit(newUser);

  Future<void> loginUser(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    final loggedInUser = User(
      id: 'logged-in-user-id-123',
      email: email,
      username: 'userLogged',
      fullName: 'Logged In User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    emit(loggedInUser);
  }

  void logoutUser() {
    emit(User(id: '')); 
  }
}