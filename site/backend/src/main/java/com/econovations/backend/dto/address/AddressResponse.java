package com.econovations.backend.dto.address;

import com.econovations.backend.domain.Address;

public record AddressResponse(
        Long id, String label, String subCounty, String town, String street, boolean isDefault) {

    public static AddressResponse from(Address a) {
        return new AddressResponse(
                a.getId(), a.getLabel(), a.getSubCounty(), a.getTown(), a.getStreet(), a.isDefault());
    }
}
