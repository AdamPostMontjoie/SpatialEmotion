//
//  CaptureFeatureTests.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/15/26.
//

import ComposableArchitecture
import XCTest


@testable import Capture_App


@MainActor
final class ContactsFeatureTests: XCTestCase {
  func testAddFlow() async {
      let store = TestStore(initialState: ContactsFeature.State()) {
        ContactsFeature()
      } withDependencies: {
          $0.uuid = .incrementing
      }
      await store.send(.addButtonTapped) {
          $0.destination = .addContact(AddContactFeature.State(contact: Contact(id: UUID(0), name: "")))
      }
      await store.send(\.destination.addContact.setName, "paul"){
          $0.$destination[case: \.addContact]?.contact.name = "paul"
      }
      await store.send(\.destination.addContact.saveButtonTapped)
      await store.receive(
            \.destination.addContact.delegate.saveContact,
            Contact(id: UUID(0), name: "paul")
          ) {
            $0.contacts = [
              Contact(id: UUID(0), name: "paul")
            ]
          }
      await store.receive(\.destination.dismiss){
          $0.destination = nil
      }
  }
    func testAddFlow_NonExhaustive() async {
        let store = TestStore(initialState: ContactsFeature.State()) {
          ContactsFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off
        await store.send(.addButtonTapped)
        await store.send(\.destination.addContact.setName, "paul]")
        await store.send(\.destination.addContact.saveButtonTapped)
        store.assert {
            $0.contacts = [
                Contact(id: UUID(0), name: "paul]")
              ]
            $0.destination = nil
        }
    }
    func testDeleteContact() async {
        let store = TestStore(
            initialState: ContactsFeature.State(
                contacts: [
                  Contact(id: UUID(0), name: "Blob"),
                  Contact(id: UUID(1), name: "Blob Jr."),
                ]
              )
            )
            {
                ContactsFeature()
            }
        await store.send(.deleteButtonTapped(id: UUID(0))) {
            $0.destination = .alert(.deleteConfirmation(id: UUID(0)))
        }
        await store.send(.destination(.presented(.alert(.confirmDeletion(id: UUID(0)))))){
            $0.contacts.remove(id:UUID(0))
            $0.destination = nil
        }
        
    }
}
