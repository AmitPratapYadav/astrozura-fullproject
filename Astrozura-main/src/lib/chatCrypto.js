const textEncoder = new TextEncoder();
const textDecoder = new TextDecoder();

const bytesToBase64 = (bytes) => {
  let binary = "";
  bytes.forEach((byte) => {
    binary += String.fromCharCode(byte);
  });
  return btoa(binary);
};

const base64ToBytes = (value) => {
  const binary = atob(String(value || ""));
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
};

const canUseWebCrypto = () => Boolean(window.crypto?.subtle);

const importChatKey = async (keyBase64) => {
  if (!canUseWebCrypto() || !keyBase64) {
    return null;
  }

  let keyBytes = base64ToBytes(keyBase64);
  if (![16, 24, 32].includes(keyBytes.byteLength)) {
    const digest = await window.crypto.subtle.digest("SHA-256", keyBytes);
    keyBytes = new Uint8Array(digest);
  }

  return window.crypto.subtle.importKey("raw", keyBytes, "AES-GCM", false, ["encrypt", "decrypt"]);
};

export const encryptChatText = async (plainText, keyBase64) => {
  if (!plainText || !canUseWebCrypto() || !keyBase64) {
    return {
      text: plainText,
      encrypted_body: null,
      encryption_iv: null,
      encryption_tag: null,
      encryption_version: null,
    };
  }

  const key = await importChatKey(keyBase64);
  if (!key) {
    return {
      text: plainText,
      encrypted_body: null,
      encryption_iv: null,
      encryption_tag: null,
      encryption_version: null,
    };
  }

  const iv = window.crypto.getRandomValues(new Uint8Array(12));
  const encrypted = await window.crypto.subtle.encrypt(
    {
      name: "AES-GCM",
      iv,
    },
    key,
    textEncoder.encode(plainText)
  );

  return {
    text: "",
    encrypted_body: bytesToBase64(new Uint8Array(encrypted)),
    encryption_iv: bytesToBase64(iv),
    encryption_tag: null,
    encryption_version: "booking-aes-gcm-v1",
  };
};

export const decryptChatText = async (message, keyBase64) => {
  if (!message?.encrypted_body || !message?.encryption_iv || !canUseWebCrypto() || !keyBase64) {
    return message?.text || "";
  }

  try {
    const key = await importChatKey(keyBase64);
    if (!key) return message?.text || "";

    const decrypted = await window.crypto.subtle.decrypt(
      {
        name: "AES-GCM",
        iv: base64ToBytes(message.encryption_iv),
      },
      key,
      base64ToBytes(message.encrypted_body)
    );

    return textDecoder.decode(decrypted);
  } catch (error) {
    console.error("Failed to decrypt chat message", error);
    return "[Encrypted message unavailable]";
  }
};
