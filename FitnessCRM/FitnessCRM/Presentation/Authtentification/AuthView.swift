//
//  AuthView.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 28.09.2026.
//

import SwiftUI

struct AuthView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var isSignUp: Bool = false
    
    var body: some View {
        VStack(spacing: CGFloat.spacingXL){
            VStack(spacing: CGFloat.spacingL){
                TextField("email", text: $authVM.email)
                    .textFieldStyle(.roundedBorder)
                
                TextField("password", text: $authVM.password)
                    .textFieldStyle(.roundedBorder)
                if isSignUp {
                    TextField("repeat password", text: $authVM.password2)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            if isSignUp {
               
                if authVM.password == authVM.password2 {
                    Button {
                        authVM.signUp()
                    } label: {
                        Text("Continue")
                    }
                } else {
                    Button {
                        
                    } label: {
                        Text("Password not the same")
                    }
                }
            } else {
                Button {
                    authVM.signIn()
                } label: {
                    Text("Continue")
                }
            }
            
            Button {
                isSignUp.toggle()
            } label: {
                Text(isSignUp ? "Sign in" : "Sign Up")
            }
        }
        .task {
            await authVM.currentUserId()
        }
    }
}
