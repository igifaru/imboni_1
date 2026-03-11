import { userRepository } from './user.repository';
import { UpdateUserDto } from './user.model';

export const userService = {
  getAll:  (page = 1, limit = 20) => userRepository.findAll((page - 1) * limit, limit),
  getById: (id: string)           => userRepository.findById(id),
  update:  (id: string, data: UpdateUserDto) => userRepository.update(id, data),
  delete:  (id: string)           => userRepository.delete(id),
  count:   ()                     => userRepository.count(),
};
