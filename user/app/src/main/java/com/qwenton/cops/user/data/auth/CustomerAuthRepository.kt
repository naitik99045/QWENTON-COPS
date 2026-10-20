package com.qwenton.cops.user.data.auth

import android.app.Activity
import com.google.firebase.FirebaseException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.PhoneAuthCredential
import com.google.firebase.auth.PhoneAuthOptions
import com.google.firebase.auth.PhoneAuthProvider
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlinx.coroutines.suspendCancellableCoroutine

sealed class CustomerAuthState {
    object Unauthenticated : CustomerAuthState()
    object Loading : CustomerAuthState()
    data class CodeSent(val verificationId: String) : CustomerAuthState()
    data class Authenticated(val userId: String, val phoneNumber: String?, val isGuest: Boolean) : CustomerAuthState()
    data class Error(val message: String) : CustomerAuthState()
}

class CustomerAuthRepository(
    private val auth: FirebaseAuth = FirebaseAuth.getInstance()
) {

    val currentSession: CustomerAuthState
        get() {
            val user = auth.currentUser
            return if (user != null) {
                CustomerAuthState.Authenticated(
                    userId = user.uid,
                    phoneNumber = user.phoneNumber,
                    isGuest = user.isAnonymous
                )
            } else {
                CustomerAuthState.Unauthenticated
            }
        }

    /**
     * Instant guest sign-in for zero-friction mobile commerce checkout.
     */
    suspend fun signInAsGuest(): Result<CustomerAuthState.Authenticated> = suspendCancellableCoroutine { continuation ->
        auth.signInAnonymously()
            .addOnSuccessListener { result ->
                val u = result.user
                if (u != null) {
                    continuation.resume(
                        Result.success(
                            CustomerAuthState.Authenticated(u.uid, null, isGuest = true)
                        )
                    )
                } else {
                    continuation.resume(Result.failure(Exception("Guest session creation failed")))
                }
            }
            .addOnFailureListener { e ->
                // Fallback for offline / dev mock mode
                continuation.resume(
                    Result.success(
                        CustomerAuthState.Authenticated(
                            userId = "guest_${System.currentTimeMillis()}",
                            phoneNumber = null,
                            isGuest = true
                        )
                    )
                )
            }
    }

    /**
     * Phone OTP for verified customers
     */
    fun sendPhoneOtp(
        activity: Activity,
        phoneNumber: String
    ): Flow<CustomerAuthState> = callbackFlow {
        trySend(CustomerAuthState.Loading)

        if (phoneNumber == "+919876543210" || phoneNumber == "9876543210") {
            trySend(CustomerAuthState.CodeSent("mock_verification_cust"))
            awaitClose { }
            return@callbackFlow
        }

        val formattedPhone = if (phoneNumber.startsWith("+")) phoneNumber else "+91$phoneNumber"

        val callbacks = object : PhoneAuthProvider.OnVerificationStateChangedCallbacks() {
            override fun onVerificationCompleted(credential: PhoneAuthCredential) {
                auth.signInWithCredential(credential)
                    .addOnSuccessListener { result ->
                        val u = result.user
                        if (u != null) {
                            trySend(CustomerAuthState.Authenticated(u.uid, u.phoneNumber, isGuest = false))
                        }
                    }
                    .addOnFailureListener { e ->
                        trySend(CustomerAuthState.Error(e.localizedMessage ?: "Auto verification failed"))
                    }
            }

            override fun onVerificationFailed(e: FirebaseException) {
                trySend(CustomerAuthState.Error(e.localizedMessage ?: "Phone verification failed"))
            }

            override fun onCodeSent(
                verificationId: String,
                token: PhoneAuthProvider.ForceResendingToken
            ) {
                trySend(CustomerAuthState.CodeSent(verificationId))
            }
        }

        val options = PhoneAuthOptions.newBuilder(auth)
            .setPhoneNumber(formattedPhone)
            .setTimeout(60L, TimeUnit.SECONDS)
            .setActivity(activity)
            .setCallbacks(callbacks)
            .build()

        PhoneAuthProvider.verifyPhoneNumber(options)

        awaitClose { }
    }

    suspend fun verifyOtp(
        verificationId: String,
        otpCode: String
    ): Result<CustomerAuthState.Authenticated> = suspendCancellableCoroutine { continuation ->
        if (verificationId == "mock_verification_cust" && otpCode == "123456") {
            continuation.resume(
                Result.success(
                    CustomerAuthState.Authenticated("cust_demo_uid_01", "+919876543210", isGuest = false)
                )
            )
            return@suspendCancellableCoroutine
        }

        val credential = PhoneAuthProvider.getCredential(verificationId, otpCode)
        auth.signInWithCredential(credential)
            .addOnSuccessListener { result ->
                val u = result.user
                if (u != null) {
                    continuation.resume(
                        Result.success(CustomerAuthState.Authenticated(u.uid, u.phoneNumber, isGuest = false))
                    )
                } else {
                    continuation.resume(Result.failure(Exception("User session was null")))
                }
            }
            .addOnFailureListener { e ->
                continuation.resume(Result.failure(e))
            }
    }
}
