package com.econovations.backend.web;

import com.econovations.backend.dto.address.AddressRequest;
import com.econovations.backend.dto.address.AddressResponse;
import com.econovations.backend.security.AppUserPrincipal;
import com.econovations.backend.service.AddressService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/addresses")
public class AddressController {

    private final AddressService addressService;

    public AddressController(AddressService addressService) {
        this.addressService = addressService;
    }

    @GetMapping
    public List<AddressResponse> list(@AuthenticationPrincipal AppUserPrincipal user) {
        return addressService.list(user.getId());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AddressResponse create(
            @AuthenticationPrincipal AppUserPrincipal user,
            @Valid @RequestBody AddressRequest request) {
        return addressService.create(user.getId(), request);
    }

    @PutMapping("/{id}")
    public AddressResponse update(
            @AuthenticationPrincipal AppUserPrincipal user,
            @PathVariable Long id,
            @Valid @RequestBody AddressRequest request) {
        return addressService.update(user.getId(), id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal AppUserPrincipal user, @PathVariable Long id) {
        addressService.delete(user.getId(), id);
    }
}
