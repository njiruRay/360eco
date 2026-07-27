package com.econovations.backend.service;

import com.econovations.backend.domain.Address;
import com.econovations.backend.domain.User;
import com.econovations.backend.dto.address.AddressRequest;
import com.econovations.backend.dto.address.AddressResponse;
import com.econovations.backend.repository.AddressRepository;
import com.econovations.backend.repository.UserRepository;
import com.econovations.backend.web.error.NotFoundException;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AddressService {

    private final AddressRepository addressRepository;
    private final UserRepository userRepository;

    public AddressService(AddressRepository addressRepository, UserRepository userRepository) {
        this.addressRepository = addressRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<AddressResponse> list(Long userId) {
        return addressRepository.findByUser_IdOrderByIsDefaultDescIdAsc(userId).stream()
                .map(AddressResponse::from)
                .toList();
    }

    @Transactional
    public AddressResponse create(Long userId, AddressRequest request) {
        User user = userRepository
                .findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found"));
        Address address = new Address();
        address.setUser(user);
        apply(address, request);
        if (request.isDefault()) {
            clearOtherDefaults(userId);
        }
        return AddressResponse.from(addressRepository.save(address));
    }

    @Transactional
    public AddressResponse update(Long userId, Long addressId, AddressRequest request) {
        Address address = addressRepository
                .findByIdAndUser_Id(addressId, userId)
                .orElseThrow(() -> new NotFoundException("Address not found"));
        apply(address, request);
        if (request.isDefault()) {
            clearOtherDefaults(userId);
            address.setDefault(true);
        }
        return AddressResponse.from(addressRepository.save(address));
    }

    @Transactional
    public void delete(Long userId, Long addressId) {
        Address address = addressRepository
                .findByIdAndUser_Id(addressId, userId)
                .orElseThrow(() -> new NotFoundException("Address not found"));
        addressRepository.delete(address);
    }

    private void apply(Address address, AddressRequest request) {
        address.setLabel(request.label());
        address.setSubCounty(request.subCounty());
        address.setTown(request.town());
        address.setStreet(request.street());
        address.setDefault(request.isDefault());
    }

    private void clearOtherDefaults(Long userId) {
        addressRepository.findByUser_IdOrderByIsDefaultDescIdAsc(userId)
                .forEach(a -> a.setDefault(false));
    }
}
