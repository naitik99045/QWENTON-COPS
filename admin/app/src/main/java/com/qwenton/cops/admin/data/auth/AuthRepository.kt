package com.qwenton.cops.admin.data.auth

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
import kotlin.coroutines.suspendCancellableCoroutine

sealed class AuthState {
    object Unauthenticated : AuthState()
    object Loading : AuthState()
    data class CodeSent(val verificationId: String) : AuthState()
    data class Authenticated(val userId: String, val phoneNumber: String?) : AuthState()
    data class Error(val message: String) : AuthState()
}

class AuthRepository(
    private val auth: FirebaseAuth = FirebaseAuth.getInstance()
) {

    val currentUser: AuthState
        get() {
            val user = auth.currentUser
            return if (user != null) {
                AuthState.Authenticated(user.uid, user.phoneNumber)
            } else {
                AuthState.Unauthenticated
            }
        }

    /**
     * Sends OTP to the provided phone number.
     * Includes dev test number support (+91 98765 43210 with OTP 123456).
     */
    fun sendOtp(
        activity: Activity,
        phoneNumber: String
    ): Flow<AuthState> = callbackFlow {
        trySend(AuthState.Loading)

        // Dev Mock Shortcut for rapid local testing
        if (phoneNumber == "+919876543210" || phoneNumber == "9876543210") {
            trySend(AuthState.CodeSent("mock_verification_id_jaipur"))
            awaitClose { }
            return@callbackFlow
        }

        val formattedPhone = if (phoneNumber.startsWith("+")) phoneNumber else "+91$phoneNumber"

        val callbacks = object : PhoneAuthProvider.OnVerificationStateChangedCallbacks() {
            override fun onVerificationCompleted(credential: PhoneAuthCredential) {
                // Auto-retrieval / instant verification
                auth.signInWithCredential(credential)
                    .addOnSuccessListener { result ->
                        val u = result.user
                        if (u != null) {
                            trySend(AuthState.Authenticated(u.uid, u.phoneNumber))
                        }
                    }
                    .addOnFailureListener { e ->
                        trySend(AuthState.Error(e.localizedMessage ?: "Instant verification failed"))
                    }
            }

            override fun onVerificationFailed(e: FirebaseException) {
                trySend(AuthState.Error(e.localizedMessage ?: "Phone verification failed"))
            }

            override fun onCodeSent(
                verificationId: String,
                token: PhoneAuthProvider.ForceResendingToken
            ) {
                trySend(AuthState.CodeSent(verificationId))
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

    /**
     * Verifies the 6-digit OTP code.
     */
    suspend fun verifyOtp(
        verificationId: String,
        otpCode: String
    ): Result<AuthState.Authenticated> = suspendCancellableCoroutine { continuation ->
        // Dev mock bypass
        if (verificationId == "mock_verification_id_jaipur" && otpCode == "123456") {
            continuation.resume(
                Result.success(
                    AuthState.Authenticated("admin_jaipur_demo_uid", "+919876543210")
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
                        Result.success(AuthState.Authenticated(u.uid, u.phoneNumber))
                    )
                } else {
                    continuation.resume(
                        Result.failure(Exception("User session was null"))
                    )
                }
            }
            .addOnFailureListener { e ->
                continuation.resume(Result.failure(e))
            }
    }

    fun signOut() {
        auth.signOut()
    }
}
